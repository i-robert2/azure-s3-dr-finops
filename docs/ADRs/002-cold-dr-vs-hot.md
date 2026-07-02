# ADR 002 — Cold DR vs. hot DR

## Status
Accepted.

## Context
The DR region can run **hot** (full capacity, always ready) or **cold** (minimal
footprint, spun up on failover). Hot DR minimizes RTO but roughly doubles cost;
cold DR is cheap but adds minutes to recovery.

## Decision
Run the DR region **cold-ish**: the **Postgres read replica stays warm**
(continuous async replication, near-zero data loss), but the **DR AKS node pool
is scaled to 0 / destroyed between drills** and rehydrated via `terraform apply`
(or a node-pool scale-up) on failover.

## Rationale
- Keeping the replica warm protects **RPO** (the expensive-to-recreate thing is
  data, not stateless pods).
- Stateless compute (AKS) is cheap and fast to bring back, so keeping it cold
  barely affects **RTO** while removing the biggest recurring cost.
- Matches the FinOps recommendation #1 (largest saving).

## Consequences
- Slightly higher RTO on a real failover (node-pool warm-up) — acceptable within
  the ≤ 15 min target.
- The runbook must include the DR compute rehydration step.
