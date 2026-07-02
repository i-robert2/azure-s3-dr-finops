#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# S3 — promote the DR Postgres read replica to a standalone read-write server.
# IRREVERSIBLE: once promoted, the replica no longer follows the primary.
# Run this only during a real failover (or the final promotion demo).
# ---------------------------------------------------------------------------
set -euo pipefail
DR_RG="${DR_RG:-rg-s3-dev-plc-001}"
REPLICA="${REPLICA:-pg-s3-dev-plc-001}"

echo "Promoting replica ${REPLICA} in ${DR_RG} to standalone..."
az postgres flexible-server replica promote \
  --resource-group "$DR_RG" \
  --name "$REPLICA" \
  --promote-mode standalone \
  --promote-option planned

echo "Promoted. The DR app can now accept writes once READ_ONLY is unset:"
echo "  helm --kube-context dr upgrade notes ./charts/notes -n app --reuse-values --set readOnly=false"
