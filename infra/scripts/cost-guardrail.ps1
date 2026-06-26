#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Report current month-to-date cost for the CFS lab resource groups and check the budget.

.DESCRIPTION
    Uses `az consumption usage list` to summarise spend across the CFS resource groups and
    surfaces the configured budget so trainers can confirm the cost guardrail is active.
    Read-only — creates/changes nothing.

.EXAMPLE
    ./cost-guardrail.ps1
#>
[CmdletBinding()]
param(
    [string]$NamePrefix = 'cfs',
    [string]$RegionToken = 'swc',
    [string]$BudgetName = 'cfs-lab-budget-swc'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) { throw 'Not logged in to Azure. Run `az login` first.' }
$subId = $account.id
Write-Host "Subscription: $($account.name) ($subId)" -ForegroundColor DarkGray

$resourceGroups = @(
    "rg-$NamePrefix-hub-$RegionToken",
    "rg-$NamePrefix-spoke-$RegionToken",
    "rg-$NamePrefix-mgmt-$RegionToken"
)

Write-Host "==> Month-to-date usage (may lag ~8-24h)..." -ForegroundColor Cyan
$usage = az consumption usage list --output json 2>$null | ConvertFrom-Json
if ($usage) {
    $usage |
        Where-Object { $_.instanceName -and ($resourceGroups -contains ($_.instanceId -split '/')[4]) } |
        Group-Object { ($_.instanceId -split '/')[4] } |
        ForEach-Object {
            $total = ($_.Group | Measure-Object -Property pretaxCost -Sum).Sum
            [pscustomobject]@{ ResourceGroup = $_.Name; Cost = [math]::Round($total, 2) }
        } | Format-Table -AutoSize
}
else {
    Write-Host "    No usage data returned yet (new subscriptions can take a day)." -ForegroundColor Yellow
}

Write-Host "==> Budget status..." -ForegroundColor Cyan
$budget = az consumption budget show --budget-name $BudgetName --output json 2>$null | ConvertFrom-Json
if ($budget) {
    [pscustomobject]@{
        Name        = $budget.name
        Amount      = $budget.amount
        TimeGrain   = $budget.timeGrain
        CurrentSpend= $budget.currentSpend.amount
    } | Format-List
}
else {
    Write-Host "    Budget '$BudgetName' not found. Deploy with budgetContactEmails set to create it." -ForegroundColor Yellow
}
