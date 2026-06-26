// Private DNS zones for the private PaaS endpoints, linked to hub and spoke.
metadata description = 'privatelink.vaultcore.azure.net and privatelink.blob.core.windows.net zones.'

@description('Resource tags.')
param tags object

@description('Hub VNet resource ID to link.')
param hubVnetResourceId string

@description('Spoke VNet resource ID to link.')
param spokeVnetResourceId string

module keyVaultZone 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
  name: 'pdns-kv-${uniqueString(spokeVnetResourceId)}'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    tags: tags
    virtualNetworkLinks: [
      {
        name: 'link-hub'
        virtualNetworkResourceId: hubVnetResourceId
        registrationEnabled: false
      }
      {
        name: 'link-spoke'
        virtualNetworkResourceId: spokeVnetResourceId
        registrationEnabled: false
      }
    ]
  }
}

module blobZone 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
  name: 'pdns-blob-${uniqueString(spokeVnetResourceId)}'
  params: {
    name: 'privatelink.blob.${environment().suffixes.storage}'
    tags: tags
    virtualNetworkLinks: [
      {
        name: 'link-hub'
        virtualNetworkResourceId: hubVnetResourceId
        registrationEnabled: false
      }
      {
        name: 'link-spoke'
        virtualNetworkResourceId: spokeVnetResourceId
        registrationEnabled: false
      }
    ]
  }
}

@description('Key Vault private DNS zone resource ID.')
output keyVaultZoneResourceId string = keyVaultZone.outputs.resourceId

@description('Blob storage private DNS zone resource ID.')
output blobZoneResourceId string = blobZone.outputs.resourceId
