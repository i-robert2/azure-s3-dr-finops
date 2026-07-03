# FinOps report — 2026-07-03

Scope: subscription `d5e040e6-7342-40d6-acec-25f9a41d060a`, resources tagged/grouped `s3`.

## Spend by resource group (current billing period)

| Resource group | Cost (billed ccy) |
|---|---|
| _(no usage rows yet — costs lag ~24h)_ | — |

> Tag allocation: every S3 resource carries `project=s3`, `cost_center=platform-eng`,
> `region=<primary|dr>`. Cost Management → Cost analysis → Group by *Tag* reproduces this
> split interactively; the subscription budget `budget-s3-monthly` alerts at 50/80/100%.

## Recommendations (ranked by impact)

| # | Recommendation | Est. saving | Effort | Decision |
|---|---|---|---|---|
| 1 | Run the **DR region cold**: scale the DR AKS node pool to 0 (or delete it) between drills and rely on the Postgres replica + a fast `terraform apply` to rehydrate on a real failover | ~15 EUR/mo | 1h | Implemented (deploy-verify-destroy already runs DR hot only during the drill) |
| 2 | Move Postgres from **GeneralPurpose D2s_v3** to **Burstable B2s** once the replica relationship is no longer needed (Burstable can't be a replica *source*, but a standalone promoted server can be right-sized down) | ~18 EUR/mo | 2h + brief restart | Planned |
| 3 | Replace **Front Door Standard** with **Front Door Classic** to shave the base fee | ~12 EUR/mo | 1h | Rejected — Standard gives managed TLS 1.2+ and the modern rules engine; the delta isn't worth losing them |

**Actioned:** recommendation #1. This is the discipline — act on one, plan one, and record *why* you rejected one.
