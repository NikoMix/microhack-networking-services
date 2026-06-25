#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy the CFS secure hub & spoke landing zone (Bicep, subscription scope).

.DESCRIPTION
    Runs a what-if preview first, then (unless -WhatIfOnly) deploys main.bicep to the
    target subscription. Uses the current az login context (OIDC in CI, az login locally).
    No secrets are read or written by this script.

.EXAMPLE
    ./deploy.ps1 -Location swedencentral
.EXAMPLE
    ./deploy.ps1 -WhatIfOnly
#>
[CmdletBinding()]
param(
    [string]$Location = 'swedencentral',
    [string]$ParameterFile = "$PSScriptRoot/../bicep/parameters/lab.bicepparam",
    [string]$TemplateFile = "$PSScriptRoot/../bicep/main.bicep",
    [string]$DeploymentName = "cfs-network-$(Get-Date -Format 'yyyyMMddHHmmss')",
    [switch]$WhatIfOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Write-Host "==> Validating Azure CLI session..." -ForegroundColor Cyan
$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) {
    throw 'Not logged in to Azure. Run `az login` (or rely on OIDC in CI) before deploying.'
}
Write-Host "    Subscription: $($account.name) ($($account.id))" -ForegroundColor DarkGray

Write-Host "==> Building Bicep template..." -ForegroundColor Cyan
az bicep build --file $TemplateFile

Write-Host "==> Running what-if preview (subscription scope)..." -ForegroundColor Cyan
az deployment sub what-if `
    --name $DeploymentName `
    --location $Location `
    --template-file $TemplateFile `
    --parameters $ParameterFile

if ($WhatIfOnly) {
    Write-Host "==> WhatIfOnly set — stopping before deploy." -ForegroundColor Yellow
    return
}

Write-Host "==> Deploying..." -ForegroundColor Cyan
az deployment sub create `
    --name $DeploymentName `
    --location $Location `
    --template-file $TemplateFile `
    --parameters $ParameterFile `
    --output json | Tee-Object -Variable result | Out-Null

Write-Host "==> Deployment complete. Outputs:" -ForegroundColor Green
az deployment sub show --name $DeploymentName --query properties.outputs --output jsonc
