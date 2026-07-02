# ADR 001 — Front Door Standard, not Premium

## Status
Accepted.

## Context
The workload needs a global entry point with health-probed, automatic
active-passive failover between two regions. Azure Front Door offers two tiers:
**Standard** and **Premium**. Premium adds a managed WAF (managed rule sets, bot
protection) and Private Link to origins, at roughly **10×** the base price
(~280 USD/mo vs ~30 EUR/mo).

## Decision
Use **Front Door Standard**.

## Rationale
- The DR/failover requirement (probes, priority origins, automatic reroute, TLS
  1.2+, custom domains) is **fully covered by Standard**.
- The Premium-only features (managed WAF, bot rules, Private Link origins) are
  not required for this lab and are a large fixed cost.
- In a regulated production deployment you would likely want Premium for the
  managed WAF — that is a deliberate, documented trade-off, not an oversight.

## Consequences
- No managed WAF at the edge; if needed later, upgrade the profile SKU.
- ~250 USD/mo saved versus Premium.
