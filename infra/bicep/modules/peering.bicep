// One side of a bidirectional VNet peering. Deployed once per resource group.
metadata description = 'Creates a virtual network peering on an existing local VNet.'

@description('Name of the existing local VNet that owns this peering.')
param localVnetName string

@description('Resource ID of the remote VNet to peer with.')
param remoteVnetResourceId string

@description('Peering child resource name.')
param peeringName string

@description('Allow this VNet gateway to be used for transit by the remote VNet.')
param allowGatewayTransit bool = false

@description('Use the remote VNet gateway (set on the spoke side when the hub hosts the gateway).')
param useRemoteGateways bool = false

resource localVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: localVnetName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: localVnet
  name: peeringName
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetResourceId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}

@description('Peering resource ID.')
output resourceId string = peering.id
