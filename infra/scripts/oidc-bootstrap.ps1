#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Bootstrap GitHub -> Azure OIDC for the CFS networking microhack (no secrets stored).

.DESCRIPTION
    Creates (or reuses) a Microsoft Entra app registration + service principal, adds a
    federated credential scoped to a GitHub repo + branch/environment, and assigns the
    RBAC role needed to deploy the subscription-scoped landing zone. Prints the three
    values to add as GitHub repository variables/secrets:
        AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID
    These are identifiers, NOT secrets — no client secret is ever created (OIDC only).

.EXAMPLE
    ./oidc-bootstrap.ps1 -GitHubOrg NikoMix -GitHubRepo microhack-networking-services -Branch main
.EXAMPLE
    ./oidc-bootstrap.ps1 -GitHubOrg NikoMix -GitHubRepo microhack-networking-services -Environment lab
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GitHubOrg,
    [Parameter(Mandatory)][string]$GitHubRepo,
    [string]$Branch = 'main',
    [string]$Environment,
    [string]$AppName = 'cfs-microhack-oidc',
    [string]$Role = 'Owner'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) { throw 'Not logged in to Azure. Run `az login` first.' }
$subId = $account.id
$tenantId = $account.tenantId
Write-Host "Subscription: $($account.name) ($subId)" -ForegroundColor DarkGray

# 1. App registration (idempotent)
$appId = az ad app list --display-name $AppName --query '[0].appId' --output tsv
if (-not $appId) {
    Write-Host "==> Creating app registration $AppName ..." -ForegroundColor Cyan
    $appId = az ad app create --display-name $AppName --query appId --output tsv
}
else {
    Write-Host "==> Reusing app registration $AppName ($appId)." -ForegroundColor DarkGray
}

# 2. Service principal (idempotent)
$spId = az ad sp list --filter "appId eq '$appId'" --query '[0].id' --output tsv
if (-not $spId) {
    Write-Host "==> Creating service principal ..." -ForegroundColor Cyan
    az ad sp create --id $appId --output none
}

# 3. Federated credential (branch and/or environment subject)
if ($Environment) {
    $subject = "repo:$GitHubOrg/${GitHubRepo}:environment:$Environment"
    $credName = "gh-$Environment"
}
else {
    $subject = "repo:$GitHubOrg/${GitHubRepo}:ref:refs/heads/$Branch"
    $credName = "gh-branch-$Branch"
}

$existing = az ad app federated-credential list --id $appId --query "[?subject=='$subject'] | [0].name" --output tsv
if (-not $existing) {
    Write-Host "==> Adding federated credential ($subject) ..." -ForegroundColor Cyan
    $fic = @{
        name        = $credName
        issuer      = 'https://token.actions.githubusercontent.com'
        subject     = $subject
        description = 'GitHub Actions OIDC for the CFS microhack'
        audiences   = @('api://AzureADTokenExchange')
    } | ConvertTo-Json -Compress
    $tmp = New-TemporaryFile
    $fic | Set-Content -Path $tmp -Encoding utf8
    az ad app federated-credential create --id $appId --parameters $tmp --output none
    Remove-Item $tmp -Force
}
else {
    Write-Host "==> Federated credential already present ($subject)." -ForegroundColor DarkGray
}

# 4. RBAC at subscription scope (deploying the LZ requires Owner or Contributor + UAA)
Write-Host "==> Assigning $Role at subscription scope ..." -ForegroundColor Cyan
az role assignment create `
    --assignee $appId `
    --role $Role `
    --scope "/subscriptions/$subId" `
    --output none 2>$null

Write-Host ""
Write-Host "==> OIDC bootstrap complete. Add these to GitHub (Settings > Secrets and variables > Actions):" -ForegroundColor Green
Write-Host "    AZURE_CLIENT_ID       = $appId"
Write-Host "    AZURE_TENANT_ID       = $tenantId"
Write-Host "    AZURE_SUBSCRIPTION_ID = $subId"
Write-Host ""
Write-Host "These are identifiers, not secrets. No client secret was created — login is OIDC only." -ForegroundColor DarkGray
