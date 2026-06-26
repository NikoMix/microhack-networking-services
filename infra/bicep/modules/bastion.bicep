// Azure Bastion for private (no public IP) admin access to spoke compute.
metadata description = 'Standard Azure Bastion host in the hub AzureBastionSubnet.'

@description('Bastion host name.')
param name string

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Hub VNet resource ID (must contain AzureBastionSubnet).')
param virtualNetworkResourceId string

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceResourceId string

module bastion 'br/public:avm/res/network/bastion-host:0.8.2' = {
  name: 'bastion-${uniqueString(name)}'
  params: {
    name: name
    location: location
    tags: tags
    virtualNetworkResourceId: virtualNetworkResourceId
    skuName: 'Standard'
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
      }
    ]
  }
}

@description('Bastion resource ID.')
output resourceId string = bastion.outputs.resourceId
