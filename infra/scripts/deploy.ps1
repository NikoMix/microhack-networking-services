#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy the CFS secure hub & spoke landing zone (Bicep, subscription scope).

.DESCRIPTION
    Runs a what-if preview first, then (unless -WhatIfOnly) deploys main.bicep to the
    target subscription. Uses the current az login context (OIDC in CI, az login locally).
    No secrets are read or written by this script.

.EXAMPLE
    ./deploy.ps1 -Component gateway   # run FIRST — provisions the 30-45 min VPN gateway
.EXAMPLE
    ./deploy.ps1 -Location swedencentral
.EXAMPLE
    ./deploy.ps1 -WhatIfOnly
#>
[CmdletBinding()]
param(
    [ValidateSet('all', 'gateway', 'hub', 'spoke', 'edge')]
    [string]$Component = 'all',
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

Write-Host "==> Running what-if preview (subscription scope, component=$Component)..." -ForegroundColor Cyan
az deployment sub what-if `
    --name $DeploymentName `
    --location $Location `
    --template-file $TemplateFile `
    --parameters $ParameterFile `
    --parameters deploymentComponent=$Component

if ($WhatIfOnly) {
    Write-Host "==> WhatIfOnly set — stopping before deploy." -ForegroundColor Yellow
    return
}

Write-Host "==> Deploying (component=$Component)..." -ForegroundColor Cyan
az deployment sub create `
    --name $DeploymentName `
    --location $Location `
    --template-file $TemplateFile `
    --parameters $ParameterFile `
    --parameters deploymentComponent=$Component `
    --output json | Tee-Object -Variable result | Out-Null

Write-Host "==> Deployment complete. Outputs:" -ForegroundColor Green
az deployment sub show --name $DeploymentName --query properties.outputs --output jsonc

# -----------------------------------------------------------------------------
# Post-deploy: approve the Front Door Premium -> Application Gateway Private Link
# connection. The shared private link request lands as "Pending" on the App
# Gateway and must be approved before Front Door can route to the origin.
# -----------------------------------------------------------------------------
if ($Component -eq 'all' -or $Component -eq 'edge') {
    Write-Host "==> Approving Front Door -> App Gateway Private Link connection..." -ForegroundColor Cyan
    $agwId = az deployment sub show --name $DeploymentName `
        --query "properties.outputs.applicationGatewayResourceId.value" --output tsv
    if ([string]::IsNullOrWhiteSpace($agwId)) {
        Write-Host "    No Application Gateway in this deployment — skipping." -ForegroundColor DarkGray
    }
    else {
        # The connection can take a short while to appear; poll briefly.
        $approved = $false
        foreach ($attempt in 1..10) {
            $pending = az network private-endpoint-connection list --id $agwId `
                --query "[?properties.privateLinkServiceConnectionState.status=='Pending'].id" `
                --output tsv 2>$null
            if (-not [string]::IsNullOrWhiteSpace($pending)) {
                foreach ($connId in ($pending -split "`n" | Where-Object { $_ })) {
                    az network private-endpoint-connection approve --id $connId `
                        --description 'Approved by lab deploy (Front Door Premium origin)' --output none
                    Write-Host "    Approved: $connId" -ForegroundColor Green
                    $approved = $true
                }
                break
            }
            Start-Sleep -Seconds 15
        }
        if (-not $approved) {
            Write-Host "    No pending connection found yet. If Front Door shows an unapproved origin, re-run:" -ForegroundColor Yellow
            Write-Host "      az network private-endpoint-connection list --id $agwId" -ForegroundColor Yellow
        }
    }
}
