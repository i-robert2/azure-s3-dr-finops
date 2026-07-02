# S3 — Annual Cost Projection (1-page)

Reporting frame: "what would this cost in production for a year, and what did the
lab actually cost?" Figures are approximate EU list prices; the point is the
**shape** of the spend and the levers, not the last decimal.

## Lab reality (this repo)
Deploy-verify-drill-report-**destroy** in a single working session.

| Item | Session cost |
|---|---|
| 2× AKS (`B2s_v2`, 1 node, a few hours) | ~1–2 EUR |
| 2× Postgres GP `D2s_v3` (primary + replica, a few hours) | ~1–2 EUR |
| Front Door Standard (base + trivial traffic) | ~cents |
| Premium ACR (hours) | ~cents |
| Cross-region replication egress | ~cents |
| **Total for the lab** | **~3–5 EUR** |

## Production steady-state (illustrative, both regions 24/7)
| Item | Monthly | Annual |
|---|---|---|
| 2× AKS node pools (right-sized, e.g. 2–3 nodes each) | ~60 EUR | ~720 EUR |
| Postgres GP primary + cross-region replica | ~50 EUR | ~600 EUR |
| Front Door **Standard** (base) + requests | ~30 EUR | ~360 EUR |
| Premium ACR (geo-replication) | ~13 EUR | ~156 EUR |
| Cross-region egress (replication + failover) | ~10 EUR | ~120 EUR |
| Log/backup storage | ~5 EUR | ~60 EUR |
| **Steady-state total** | **~168 EUR/mo** | **~2,016 EUR/yr** |

## Levers (see FinOps report for the actioned ones)
1. **Cold DR** — scale the DR node pool to 0 between incidents/drills → the largest single saving; DR spins up on failover via `terraform apply`.
2. **Right-size Postgres** — GP is required *only while replicating*; a promoted standalone can drop to Burstable.
3. **Front Door tier** — Standard chosen over Premium (~280 USD/mo) deliberately; documented in `docs/ADRs/001-front-door-standard.md`.

## Budget guardrail
- Subscription budget `budget-s3-monthly` = 150 (billed ccy), alerting at **50 / 80 / 100 %**.
- Every resource is tagged `project=s3`, `cost_center=platform-eng`, `region=<primary|dr>` so spend is attributable.
