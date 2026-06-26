// Key Vault reachable only via a Private Endpoint (no public network access).
metadata description = 'RBAC Key Vault with purge protection ON and a private endpoint.'

@description('Key Vault name (3-24 alphanumeric/hyphen).')
param name string

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Private endpoint subnet resource ID.')
param privateEndpointSubnetResourceId string

@description('Key Vault private DNS zone resource ID.')
param privateDnsZoneResourceId string

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceResourceId string

module vault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  name: 'kv-${uniqueString(name)}'
  params: {
    name: name
    location: location
    tags: tags
    sku: 'standard'
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
      }
    ]
    privateEndpoints: [
      {
        subnetResourceId: privateEndpointSubnetResourceId
        service: 'vault'
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZoneResourceId
            }
          ]
        }
      }
    ]
  }
}

@description('Key Vault resource ID.')
output resourceId string = vault.outputs.resourceId

@description('Key Vault name.')
output name string = vault.outputs.name
