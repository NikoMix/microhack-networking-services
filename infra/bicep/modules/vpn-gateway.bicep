// Route-based VPN Virtual Network Gateway (real hybrid connectivity).
// NOTE: ExpressRoute is DESIGN-ONLY in this microhack — no circuit is provisioned.
metadata description = 'VpnGw1 route-based VPN gateway in the hub GatewaySubnet.'

@description('VPN gateway name.')
param name string

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Hub VNet resource ID (must contain GatewaySubnet).')
param virtualNetworkResourceId string

@description('Gateway SKU. VpnGw1 keeps lab cost down while remaining production-shaped.')
param skuName string = 'VpnGw1'

module gateway 'br/public:avm/res/network/virtual-network-gateway:0.11.1' = {
  name: 'vpngw-${uniqueString(name)}'
  params: {
    name: name
    location: location
    tags: tags
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    skuName: skuName
    vpnGatewayGeneration: 'Generation1'
    virtualNetworkResourceId: virtualNetworkResourceId
    clusterSettings: {
      clusterMode: 'activePassiveNoBgp'
    }
  }
}

@description('VPN gateway resource ID.')
output resourceId string = gateway.outputs.resourceId
