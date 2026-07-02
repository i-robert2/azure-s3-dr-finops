<#
.SYNOPSIS
  S3 DR drill — simulate a primary-region outage, measure RTO/RPO through Azure
  Front Door, then restore. Idempotent and self-cleaning: even if aborted, it
  scales the primary app back up on exit.

.DESCRIPTION
  Fault model: scale the primary cluster's `notes` deployment to 0 so its
  ingress fails Front Door's /api/healthz probe. Front Door then routes to the
  DR origin (priority 2). We poll /api/whoami through the Front Door endpoint
  and record the time to fail over (RTO). A marker row written to the primary
  just before the outage is checked on the DR replica to evidence RPO.

  This drill does NOT promote the replica (that is irreversible — see
  promote-replica.sh). It measures failover + data-lag only, so it is repeatable.

.PARAMETER FrontDoorHost
  The Front Door endpoint host (e.g. endpoint-s3-xxxx.z01.azurefd.net).

.PARAMETER OutputReport
  Path to write the postmortem markdown.
#>
param(
  [Parameter(Mandatory = $true)][string]$FrontDoorHost,
  [string]$PrimaryContext = "primary",
  [string]$DrContext = "dr",
  [string]$Namespace = "app",
  [string]$OutputReport = "docs/DR-DRILL-$(Get-Date -Format yyyy-MM-dd).md"
)

$ErrorActionPreference = "Stop"
$base = "https://$FrontDoorHost"

function Get-ServingRegion {
  try { return (Invoke-RestMethod -Uri "$base/api/whoami" -TimeoutSec 10).region } catch { return "unreachable" }
}

$restored = $false
function Restore-Primary {
  if ($script:restored) { return }
  Write-Host "Restoring primary (scale notes -> 1)..."
  kubectl --context $PrimaryContext -n $Namespace scale deploy/notes --replicas=1 | Out-Null
  $script:restored = $true
}

try {
  Write-Host "== Baseline =="
  $baseRegion = Get-ServingRegion
  Write-Host "Front Door currently serves: $baseRegion"

  # Marker write to primary (through Front Door while primary is healthy).
  $marker = "drill-marker-$(Get-Date -Format yyyyMMddHHmmss)"
  Invoke-RestMethod -Uri "$base/api/notes" -Method Post -ContentType 'application/json' `
    -Body (@{ title = $marker } | ConvertTo-Json) -TimeoutSec 10 | Out-Null
  $markerTime = Get-Date
  Write-Host "Wrote marker to primary: $marker"

  Write-Host "== Inject fault: scale primary notes -> 0 =="
  kubectl --context $PrimaryContext -n $Namespace scale deploy/notes --replicas=0 | Out-Null
  $faultStart = Get-Date

  Write-Host "== Measure RTO: poll Front Door until it serves DR =="
  $rto = $null
  while (((Get-Date) - $faultStart).TotalSeconds -lt 600) {
    $r = Get-ServingRegion
    if ($r -and $r -ne $baseRegion -and $r -ne "unreachable") {
      $rto = ((Get-Date) - $faultStart).TotalSeconds
      Write-Host "Failed over to '$r' after $([math]::Round($rto,1))s"
      break
    }
    Start-Sleep -Seconds 3
  }

  Write-Host "== RPO evidence: is the marker present on the DR replica? =="
  $onReplica = $false
  try {
    $notes = (Invoke-RestMethod -Uri "$base/api/notes" -TimeoutSec 10).notes
    $onReplica = [bool]($notes | Where-Object { $_.title -eq $marker })
  } catch {}
  Write-Host "Marker replicated to DR: $onReplica"

  Write-Host "== Restore primary =="
  Restore-Primary
  $recovered = $null
  $restoreStart = Get-Date
  while (((Get-Date) - $restoreStart).TotalSeconds -lt 300) {
    if ((Get-ServingRegion) -eq $baseRegion) { $recovered = ((Get-Date) - $restoreStart).TotalSeconds; break }
    Start-Sleep -Seconds 3
  }

  $report = @"
# DR drill — $(Get-Date -Format 'yyyy-MM-dd HH:mm')

Fault model: primary cluster ``notes`` deployment scaled to 0 (ingress fails the
Front Door /api/healthz probe). Front Door endpoint: ``$FrontDoorHost``.

| Metric | Target (SLO) | Measured |
|---|---|---|
| RTO — Front Door failover to DR | <= 15 min | **$([math]::Round($rto,1)) s** |
| RPO — marker row present on replica at cutover | <= 5 min lag | **$( if ($onReplica) { 'replicated (0 loss for marker)' } else { 'NOT yet replicated' } )** |
| Time to restore primary serving | — | **$([math]::Round($recovered,1)) s** |

Baseline serving region: ``$baseRegion``. Marker: ``$marker`` at $($markerTime.ToString('HH:mm:ss')).

## 5-Whys (worst observed gap)
1. Why any user-visible delay? Front Door only reroutes after N failed probes.
2. Why N probes? Load-balancing sample_size=4, successful_samples_required=3.
3. Why those values? Balance between flap-resistance and fast failover.
4. Why not lower? Too-aggressive probing flaps on transient blips.
5. Root: RTO is bounded by (probe interval x samples). Tunable in the origin group.

## Actions
- [ ] If RTO must drop, lower ``interval_in_seconds`` and ``sample_size`` in the origin group.
- [ ] Automate replica promotion (promote-replica.sh) into the runbook for a real outage.
"@
  New-Item -ItemType Directory -Force -Path (Split-Path $OutputReport) | Out-Null
  $report | Out-File $OutputReport -Encoding utf8
  Write-Host "Wrote $OutputReport"
}
finally {
  Restore-Primary
}
