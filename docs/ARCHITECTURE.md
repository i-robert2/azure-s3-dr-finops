# S3 — Architecture (1-page summary)

## Purpose
Active-passive, multi-region disaster recovery for a stateful Kubernetes workload
on Azure, with a **measured** failover drill and a **quantified** cost practice.

## Regions
- **Primary:** `swedencentral` (`sdc`)
- **DR:** `polandcentral` (`plc`)

> These two were chosen because they are the only EU regions where this
> subscription can run the required `Standard_B2s_v2` nodes **and** Postgres
> Flexible Server (West Europe is `NotAvailableForSubscription`; North Europe /
> Germany / others don't offer `B2s_v2`). See `docs/ADRs` and the README's
> *Issues we hit*.

## Components
| Layer | Resource | Notes |
|---|---|---|
| Edge | Azure Front Door **Standard** | One endpoint, one origin group, two priority origins, `/api/healthz` probe, automatic failover |
| Compute | 2× AKS (`B2s_v2`, 1 node) | Identical Helm release; DR runs `READ_ONLY=true` |
| Data | Postgres Flexible **GP_Standard_D2s_v3** primary + **cross-region read replica** | Async replication; replica promoted on real failover |
| Images | **Premium ACR**, geo-replicated | Each cluster pulls from its in-region replica |
| Cost | Cost Management **budget** + tag allocation | Alerts at 50/80/100% |

## Data flow
1. Users hit the Front Door endpoint (HTTPS).
2. Front Door forwards to the **primary** ingress (priority 1) while its probe is healthy.
3. The app reads/writes the **primary** Postgres; rows replicate async to the DR replica.
4. On a primary-region failure, Front Door's probe fails and traffic shifts to the **DR** origin (priority 2).
5. During a real outage the DR replica is **promoted** to read-write and the DR app's `READ_ONLY` is cleared.

## RTO / RPO
- **RTO target ≤ 15 min** — bounded by Front Door probe interval × required samples.
- **RPO target ≤ 5 min** — bounded by async replication lag.
- Measured values are recorded per drill in `docs/DR-DRILL-<date>.md`.

## Isolation & security
- Both Postgres servers are VNet-integrated, **no public access**.
- ACR admin account disabled; clusters pull via **managed identity** (`AcrPull`).
- Front Door serves HTTPS only (HTTP redirected); origins terminate Let's Encrypt certs.
- DR rejects writes (`503`) until an explicit promotion — prevents split-brain.
