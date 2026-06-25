// Storage account with shared-key auth disabled, reachable only via Private Endpoint.
metadata description = 'RBAC-only Storage account (blob) with a private endpoint.'

@description('Storage account name (3-24 lowercase alphanumeric).')
param name string

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Private endpoint subnet resource ID.')
param privateEndpointSubnetResourceId string

@description('Blob private DNS zone resource ID.')
param blobPrivateDnsZoneResourceId string

module account 'br/public:avm/res/storage/storage-account:0.32.1' = {
  name: 'st-${uniqueString(name)}'
  params: {
    name: name
    location: location
    tags: tags
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    allowSharedKeyAccess: false
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    privateEndpoints: [
      {
        subnetResourceId: privateEndpointSubnetResourceId
        service: 'blob'
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: blobPrivateDnsZoneResourceId
            }
          ]
        }
      }
    ]
  }
}

@description('Storage account resource ID.')
output resourceId string = account.outputs.resourceId

@description('Storage account name.')
output name string = account.outputs.name
