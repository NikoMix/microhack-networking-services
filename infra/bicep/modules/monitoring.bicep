// Central Log Analytics workspace — single monitoring sink for the landing zone.
metadata description = 'Log Analytics workspace used by firewall, bastion, app gateway, Front Door and flow logs.'

@description('Workspace name.')
param name string

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Data retention in days.')
param retentionInDays int = 30

module workspace 'br/public:avm/res/operational-insights/workspace:0.15.1' = {
  name: 'law-${uniqueString(name)}'
  params: {
    name: name
    location: location
    tags: tags
    dataRetention: retentionInDays
    skuName: 'PerGB2018'
  }
}

@description('Resource ID of the Log Analytics workspace.')
output resourceId string = workspace.outputs.resourceId

@description('Name of the Log Analytics workspace.')
output name string = workspace.outputs.name
