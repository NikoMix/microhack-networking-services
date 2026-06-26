// Workload spoke VNet: NSGs, a route table forcing egress through the firewall,
// and five purpose-built subnets (workload, private endpoints, app gateway,
// app gateway private link, LB).
metadata description = 'Spoke VNet with default-route-to-firewall and segmented subnets.'

@description('Spoke VNet name.')
param name string

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Spoke VNet address space, e.g. 10.1.0.0/16.')
param addressPrefix string

@description('Workload subnet prefix.')
param workloadSubnetPrefix string

@description('Private endpoint subnet prefix.')
param privateEndpointSubnetPrefix string

@description('Application Gateway subnet prefix.')
param appGatewaySubnetPrefix string

@description('Application Gateway Private Link subnet prefix (dedicated; network policies disabled).')
param appGatewayPrivateLinkSubnetPrefix string

@description('Internal load balancer subnet prefix.')
param loadBalancerSubnetPrefix string

@description('Firewall private IP used as the default-route next hop.')
param firewallPrivateIp string

// NSG for the workload subnet: only Bastion may reach SSH/RDP; deny direct internet in.
module workloadNsg 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: 'nsg-workload-${uniqueString(name)}'
  params: {
    name: '${name}-workload-nsg'
    location: location
    tags: tags
    securityRules: [
      {
        name: 'Allow-Bastion-Admin-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.1.0/26'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
      {
        name: 'Deny-Internet-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG for the Application Gateway subnet: required platform + client ingress rules.
module appGwNsg 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: 'nsg-appgw-${uniqueString(name)}'
  params: {
    name: '${name}-appgw-nsg'
    location: location
    tags: tags
    securityRules: [
      {
        name: 'Allow-GatewayManager-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
        }
      }
      {
        name: 'Allow-AzureLoadBalancer-Inbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'Allow-Http-Inbound'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
    ]
  }
}

// Route table: send all spoke egress to the central firewall.
module routeTable 'br/public:avm/res/network/route-table:0.5.0' = {
  name: 'rt-spoke-${uniqueString(name)}'
  params: {
    name: '${name}-rt'
    location: location
    tags: tags
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

module vnet 'br/public:avm/res/network/virtual-network:0.9.0' = {
  name: 'spoke-vnet-${uniqueString(name)}'
  params: {
    name: name
    location: location
    tags: tags
    addressPrefixes: [
      addressPrefix
    ]
    subnets: [
      {
        name: 'snet-workload'
        addressPrefix: workloadSubnetPrefix
        networkSecurityGroupResourceId: workloadNsg.outputs.resourceId
        routeTableResourceId: routeTable.outputs.resourceId
      }
      {
        name: 'snet-pe'
        addressPrefix: privateEndpointSubnetPrefix
      }
      {
        name: 'snet-appgw'
        addressPrefix: appGatewaySubnetPrefix
        networkSecurityGroupResourceId: appGwNsg.outputs.resourceId
      }
      {
        // Dedicated subnet hosting the Application Gateway Private Link service NICs.
        // Front Door Premium connects to the App Gateway frontend through this subnet,
        // which therefore must disable private-link-service network policies.
        name: 'snet-agw-pl'
        addressPrefix: appGatewayPrivateLinkSubnetPrefix
        privateLinkServiceNetworkPolicies: 'Disabled'
      }
      {
        name: 'snet-lb'
        addressPrefix: loadBalancerSubnetPrefix
        routeTableResourceId: routeTable.outputs.resourceId
      }
    ]
  }
}

@description('Spoke VNet resource ID.')
output resourceId string = vnet.outputs.resourceId

@description('Spoke VNet name.')
output name string = vnet.outputs.name

@description('Workload subnet resource ID.')
output workloadSubnetResourceId string = vnet.outputs.subnetResourceIds[0]

@description('Private endpoint subnet resource ID.')
output privateEndpointSubnetResourceId string = vnet.outputs.subnetResourceIds[1]

@description('Application Gateway subnet resource ID.')
output appGatewaySubnetResourceId string = vnet.outputs.subnetResourceIds[2]

@description('Application Gateway Private Link subnet resource ID.')
output appGatewayPrivateLinkSubnetResourceId string = vnet.outputs.subnetResourceIds[3]

@description('Internal load balancer subnet resource ID.')
output loadBalancerSubnetResourceId string = vnet.outputs.subnetResourceIds[4]

@description('Workload NSG resource ID (used as flow-log target).')
output workloadNsgResourceId string = workloadNsg.outputs.resourceId
