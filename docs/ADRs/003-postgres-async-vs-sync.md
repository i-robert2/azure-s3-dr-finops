# ADR 003 — Postgres async replication (not sync)

## Status
Accepted.

## Context
The cross-region Postgres replica can, in principle, be kept in sync (zero data
loss, higher write latency) or async (small potential data loss, no write-path
penalty). Azure Postgres Flexible Server **cross-region read replicas are async**
by design.

## Decision
Use **async** cross-region replication (the only option for cross-region read
replicas), and set the **RPO target to ≤ 5 min** accordingly.

## Rationale
- Synchronous cross-region commit would add tens of milliseconds to every write
  (Sweden ↔ Poland round-trip), degrading the primary's user experience.
- The workload tolerates a small, bounded data-loss window on a regional
  disaster; that window is the RPO we measure in the drill.
- GeneralPurpose tier is required for read replicas (Burstable can't be a
  source) — so the primary runs `GP_Standard_D2s_v3`.

## Consequences
- Non-zero RPO: transactions committed on the primary but not yet shipped are
  lost if the primary region is destroyed. Measured per drill.
- On promotion, the replica becomes an independent read-write server; the old
  replication link is gone (irreversible) — reflected in the runbook.
