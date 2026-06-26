// Network Watcher + NSG flow logs with Traffic Analytics.
// NOTE: Azure allows ONE Network Watcher per region per subscription. If the
// auto-created NetworkWatcherRG/NetworkWatcher_<region> already exists, set
// deployNetworkWatcher=false in main and attach flow logs to that instance.
metadata description = 'NSG flow logs (v2) to storage with Traffic Analytics into Log Analytics.'

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Storage account name for flow logs.')
param flowLogsStorageName string

@description('NSG resource ID whose traffic is logged.')
param targetNsgResourceId string

@description('Log Analytics workspace resource ID for Traffic Analytics.')
param logAnalyticsWorkspaceResourceId string

// Flow logs require a general-purpose v2 storage account in the same region.
module flowLogsStorage 'br/public:avm/res/storage/storage-account:0.32.1' = {
  name: 'st-flow-${uniqueString(flowLogsStorageName)}'
  params: {
    name: flowLogsStorageName
    location: location
    tags: tags
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
  }
}

module networkWatcher 'br/public:avm/res/network/network-watcher:0.5.1' = {
  name: 'nw-${uniqueString(location)}'
  params: {
    name: 'NetworkWatcher_${location}'
    location: location
    tags: tags
    flowLogs: [
      {
        name: 'fl-workload-nsg'
        targetResourceId: targetNsgResourceId
        storageResourceId: flowLogsStorage.outputs.resourceId
        enabled: true
        formatVersion: 2
        retentionInDays: 30
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        trafficAnalyticsInterval: 60
      }
    ]
  }
}

@description('Network Watcher resource ID.')
output resourceId string = networkWatcher.outputs.resourceId
