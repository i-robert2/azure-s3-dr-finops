# S3 — Failover Runbook (1-page)

**Scenario:** the primary region (`swedencentral`) is degraded or unreachable.
**Goal:** restore user-facing service from the DR region (`polandcentral`) and
recover write capability. **Owner:** platform on-call.

## 0. Confirm the incident (≤ 2 min)
```powershell
$FD = "<endpoint-s3-xxxx>.azurefd.net"
curl "https://$FD/api/whoami"          # which region is serving?
kubectl --context primary -n app get pods
```
- If Front Door already reports `region=dr`, automatic failover has occurred — skip to step 2.

## 1. Force/confirm Front Door failover (automatic, ≤ 15 min)
- Front Door health-probes `/api/healthz` every 30s; after 3 failed samples it
  routes to the DR origin (priority 2). No manual action needed.
- Verify: `curl https://$FD/api/whoami` returns `region=dr`.

## 2. Promote the DR database to read-write (≤ 10 min)
```bash
DR_RG=rg-s3-dev-plc-001 REPLICA=pg-s3-dev-plc-001 ./scripts/promote-replica.sh
```
- **Irreversible.** Only do this when the primary is genuinely lost or during a
  planned drill's promotion demo.

## 3. Enable writes on the DR app
```powershell
helm --kube-context dr upgrade notes ./charts/notes -n app --reuse-values --set readOnly=false
curl -X POST "https://$FD/api/notes" -H "content-type: application/json" -d '{"title":"post-failover"}'
```
- Expect `201`. The service is now fully operational from DR.

## 4. Communicate
- Post status; note the failover time and any data-loss window (from the drill/monitoring).

## 5. Recover / fail back (post-incident)
- Rebuild the primary region with `terraform apply` in `terraform/primary`.
- Re-seed data from the promoted DR server (now the source of truth).
- Optionally re-establish a replica in the original primary and cut Front Door back.

## Roll-back of a *drill* (no promotion)
```powershell
kubectl --context primary -n app scale deploy/notes --replicas=1   # restore primary
```
- `scripts/dr-drill.ps1` does this automatically on exit.

## Key facts
| Item | Value |
|---|---|
| Front Door endpoint | `<endpoint-s3-xxxx>.azurefd.net` |
| Primary AKS / RG | `aks-s3-dev-sdc-001` / `rg-s3-dev-sdc-001` |
| DR AKS / RG | `aks-s3-dev-plc-001` / `rg-s3-dev-plc-001` |
| Primary PG / replica | `pg-s3-dev-sdc-001` / `pg-s3-dev-plc-001` |
