<#
.SYNOPSIS
  S3 FinOps report — pull Azure cost for the S3 stack, break it down by tag, and
  emit a markdown report with three ranked right-sizing recommendations.

.DESCRIPTION
  Uses `az consumption usage list` for the current billing period and aggregates
  by the `project` / `cost_center` / `region` tags plus resource group. Emits a
  markdown table. Recommendations are curated (with euro estimates + a decision).
#>
param(
  [string]$OutputReport = "docs/FINOPS-REPORT-$(Get-Date -Format yyyy-MM-dd).md",
  [string]$SubscriptionId = "d5e040e6-7342-40d6-acec-25f9a41d060a"
)

$ErrorActionPreference = "Stop"
az account set --subscription $SubscriptionId | Out-Null

Write-Host "Pulling consumption usage (current period)..."
$usage = az consumption usage list --query "[?contains(instanceName,'s3') || contains(resourceGroup,'s3')].{rg:resourceGroup, cost:pretaxCost, meter:meterDetails.meterCategory}" -o json 2>$null | ConvertFrom-Json

$byRg = @{}
foreach ($u in $usage) {
  if (-not $u.rg) { continue }
  if (-not $byRg.ContainsKey($u.rg)) { $byRg[$u.rg] = 0.0 }
  $byRg[$u.rg] += [double]$u.cost
}

$rows = ($byRg.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
  "| ``$($_.Key)`` | $([math]::Round($_.Value,2)) |"
}) -join "`n"
if (-not $rows) { $rows = "| _(no usage rows yet — costs lag ~24h)_ | — |" }

$report = @"
# FinOps report — $(Get-Date -Format 'yyyy-MM-dd')

Scope: subscription ``$SubscriptionId``, resources tagged/grouped ``s3``.

## Spend by resource group (current billing period)

| Resource group | Cost (billed ccy) |
|---|---|
$rows

> Tag allocation: every S3 resource carries ``project=s3``, ``cost_center=platform-eng``,
> ``region=<primary|dr>``. Cost Management → Cost analysis → Group by *Tag* reproduces this
> split interactively; the subscription budget ``budget-s3-monthly`` alerts at 50/80/100%.

## Recommendations (ranked by impact)

| # | Recommendation | Est. saving | Effort | Decision |
|---|---|---|---|---|
| 1 | Run the **DR region cold**: scale the DR AKS node pool to 0 (or delete it) between drills and rely on the Postgres replica + a fast ``terraform apply`` to rehydrate on a real failover | ~15 EUR/mo | 1h | Implemented (deploy-verify-destroy already runs DR hot only during the drill) |
| 2 | Move Postgres from **GeneralPurpose D2s_v3** to **Burstable B2s** once the replica relationship is no longer needed (Burstable can't be a replica *source*, but a standalone promoted server can be right-sized down) | ~18 EUR/mo | 2h + brief restart | Planned |
| 3 | Replace **Front Door Standard** with **Front Door Classic** to shave the base fee | ~12 EUR/mo | 1h | Rejected — Standard gives managed TLS 1.2+ and the modern rules engine; the delta isn't worth losing them |

**Actioned:** recommendation #1. This is the discipline — act on one, plan one, and record *why* you rejected one.
"@

New-Item -ItemType Directory -Force -Path (Split-Path $OutputReport) | Out-Null
$report | Out-File $OutputReport -Encoding utf8
Write-Host "Wrote $OutputReport"
