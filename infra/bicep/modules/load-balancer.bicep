// Internal (private) Standard Load Balancer fronting the workload pool.
metadata description = 'Internal Standard Load Balancer with a static private frontend.'

@description('Load balancer name.')
param name string

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Internal LB subnet resource ID.')
param subnetResourceId string

@description('Static private frontend IP.')
param privateIpAddress string

module loadBalancer 'br/public:avm/res/network/load-balancer:0.7.1' = {
  name: 'ilb-${uniqueString(name)}'
  params: {
    name: name
    location: location
    tags: tags
    skuName: 'Standard'
    frontendIPConfigurations: [
      {
        name: 'feInternal'
        subnetResourceId: subnetResourceId
        privateIPAddress: privateIpAddress
      }
    ]
    backendAddressPools: [
      {
        name: 'workloadPool'
      }
    ]
    probes: [
      {
        name: 'httpProbe'
        protocol: 'Tcp'
        port: 80
        intervalInSeconds: 5
        numberOfProbes: 2
      }
    ]
    loadBalancingRules: [
      {
        name: 'http'
        frontendIPConfigurationName: 'feInternal'
        backendAddressPoolName: 'workloadPool'
        protocol: 'Tcp'
        frontendPort: 80
        backendPort: 80
        probeName: 'httpProbe'
        idleTimeoutInMinutes: 4
        enableFloatingIP: false
        disableOutboundSnat: true
      }
    ]
  }
}

@description('Load balancer resource ID.')
output resourceId string = loadBalancer.outputs.resourceId
