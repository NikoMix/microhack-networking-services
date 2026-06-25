// Hub virtual network with the three platform subnets (Firewall, Bastion, Gateway).
metadata description = 'Hub VNet hosting Azure Firewall, Bastion and the VPN gateway.'

@description('Hub VNet name.')
param name string

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Hub VNet address space, e.g. 10.0.0.0/16.')
param addressPrefix string

@description('AzureFirewallSubnet prefix (min /26).')
param firewallSubnetPrefix string

@description('AzureBastionSubnet prefix (min /26).')
param bastionSubnetPrefix string

@description('GatewaySubnet prefix (min /27).')
param gatewaySubnetPrefix string

module vnet 'br/public:avm/res/network/virtual-network:0.9.0' = {
  name: 'hub-vnet-${uniqueString(name)}'
  params: {
    name: name
    location: location
    tags: tags
    addressPrefixes: [
      addressPrefix
    ]
    subnets: [
      // Reserved subnet names are mandatory for these platform services.
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: firewallSubnetPrefix
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: bastionSubnetPrefix
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: gatewaySubnetPrefix
      }
    ]
  }
}

@description('Hub VNet resource ID.')
output resourceId string = vnet.outputs.resourceId

@description('Hub VNet name.')
output name string = vnet.outputs.name
