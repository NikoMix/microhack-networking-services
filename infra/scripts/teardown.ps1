#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tear down the CFS lab landing zone by deleting its resource groups.

.DESCRIPTION
    Deletes the three CFS resource groups (hub / spoke / mgmt) plus the auto-created
    NetworkWatcherRG flow-log resources are left intact (shared per-region RG).
    Requires an explicit confirmation token to avoid accidental deletion.

.EXAMPLE
    ./teardown.ps1 -Confirm 'DELETE'
#>
[CmdletBinding()]
param(
    [string]$NamePrefix = 'cfs',
    [string]$RegionToken = 'swc',
    [Parameter(Mandatory)][string]$Confirm,
    [switch]$NoWait
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($Confirm -ne 'DELETE') {
    throw "Refusing to tear down: pass -Confirm 'DELETE' to proceed."
}

$resourceGroups = @(
    "rg-$NamePrefix-hub-$RegionToken",
    "rg-$NamePrefix-spoke-$RegionToken",
    "rg-$NamePrefix-mgmt-$RegionToken"
)

$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) { throw 'Not logged in to Azure. Run `az login` first.' }
Write-Host "Subscription: $($account.name) ($($account.id))" -ForegroundColor DarkGray

foreach ($rg in $resourceGroups) {
    $exists = az group exists --name $rg | ConvertFrom-Json
    if (-not $exists) {
        Write-Host "==> $rg does not exist — skipping." -ForegroundColor Yellow
        continue
    }
    Write-Host "==> Deleting resource group $rg ..." -ForegroundColor Cyan
    if ($NoWait) {
        az group delete --name $rg --yes --no-wait
    }
    else {
        az group delete --name $rg --yes
    }
}

Write-Host "==> Teardown requested. Note: VPN/Firewall deletes can take 10-20 min." -ForegroundColor Green
