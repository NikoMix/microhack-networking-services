// =============================================================================
//  Contoso Financial Services (CFS) — Secure Hub & Spoke Landing Zone
//  Module B Networking microhack — PRIMARY IaC (Bicep, Azure Verified Modules)
// -----------------------------------------------------------------------------
//  Topology: CAF/ALZ-aligned hub & spoke. Central egress via Azure Firewall,
//  private admin via Bastion, hybrid via VPN gateway (ExpressRoute = design only),
//  private PaaS via Private Link, private compute (no public IP), internal LB,
//  Application Gateway + WAF, and global delivery via Front Door + WAF.
//  Deployed subscription-scoped: creates resource groups, then AVM modules.
// =============================================================================

targetScope = 'subscription'

// -----------------------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------------------

@description('Primary Azure region. Fallback to westeurope if swedencentral capacity is constrained.')
@allowed([
  'swedencentral'
  'westeurope'
])
param location string = 'swedencentral'

@description('Short region token used in resource names (swc = Sweden Central).')
param regionToken string = 'swc'

@description('Workload / customer prefix used in every resource name.')
param namePrefix string = 'cfs'

@description('Environment tag value.')
param environmentName string = 'lab'

@description('Deploy a real VPN Virtual Network Gateway (slow + adds cost). ExpressRoute remains design-only either way.')
param deployVpnGateway bool = true

@description('Deploy the global Azure Front Door + WAF profile.')
param deployFrontDoor bool = true

@description('Deploy Network Watcher + NSG flow logs. Disable if the subscription already owns the regional Network Watcher (one per region).')
param deployNetworkWatcher bool = true

@description('Admin username for the private Linux VM.')
param adminUsername string = 'cfsadmin'

@description('SSH public key (OpenSSH format) authorized on the private VM. Required to actually deploy compute; password auth is disabled.')
param adminSshPublicKey string = ''

@description('Size of the private workload VM.')
param vmSize string = 'Standard_D2s_v5'

@description('Monthly budget amount (currency of the subscription) used for the cost guardrail.')
param budgetAmount int = 200

@description('Email addresses notified by the budget alerts. Budget is only created when at least one email is supplied.')
param budgetContactEmails array = []

@description('UTC start date (first of month) for the budget window.')
param budgetStartDate string = '2026-06-01'

// -----------------------------------------------------------------------------
// Variables — naming & address space
// -----------------------------------------------------------------------------

var tags = {
  env: environmentName
  workload: namePrefix
  solution: 'module-b-networking-microhack'
  managedBy: 'bicep-avm'
}

// Naming helper: cfs-<role>-<type>-<region>
func resName(prefix string, role string, typ string, region string) string => '${prefix}-${role}-${typ}-${region}'

var names = {
  rgHub: 'rg-${namePrefix}-hub-${regionToken}'
  rgSpoke: 'rg-${namePrefix}-spoke-${regionToken}'
  rgMgmt: 'rg-${namePrefix}-mgmt-${regionToken}'
  law: resName(namePrefix, 'mgmt', 'law', regionToken)
  hubVnet: resName(namePrefix, 'hub', 'vnet', regionToken)
  spokeVnet: resName(namePrefix, 'app', 'vnet', regionToken)
  firewall: resName(namePrefix, 'hub', 'afw', regionToken)
  firewallPolicy: resName(namePrefix, 'hub', 'afwp', regionToken)
  bastion: resName(namePrefix, 'hub', 'bas', regionToken)
  vpnGateway: resName(namePrefix, 'hub', 'vpngw', regionToken)
  keyVault: take(replace('${namePrefix}appkv${uniqueString(subscription().id)}', '-', ''), 24)
  storage: take(toLower(replace('${namePrefix}app${uniqueString(subscription().id)}', '-', '')), 24)
  vm: '${namePrefix}-app-vm-${regionToken}'
  ilb: resName(namePrefix, 'app', 'ilb', regionToken)
  appGateway: resName(namePrefix, 'app', 'agw', regionToken)
  appGwWafPolicy: take(replace(resName(namePrefix, 'app', 'agwwaf', regionToken), '-', ''), 80)
  frontDoor: resName(namePrefix, 'edge', 'afd', regionToken)
  frontDoorWafPolicy: take(replace('${namePrefix}edgeafdwaf${regionToken}', '-', ''), 80)
  flowLogsStorage: take(toLower(replace('${namePrefix}flow${uniqueString(subscription().id)}', '-', '')), 24)
}

var hubAddressSpace = '10.0.0.0/16'
var spokeAddressSpace = '10.1.0.0/16'

var hubSubnets = {
  firewall: '10.0.0.0/26'
  bastion: '10.0.1.0/26'
  gateway: '10.0.2.0/27'
}

var spokeSubnets = {
  workload: '10.1.0.0/24'
  privateEndpoints: '10.1.1.0/24'
  appGateway: '10.1.2.0/24'
  loadBalancer: '10.1.3.0/24'
}

var ilbPrivateIp = '10.1.3.10'

// -----------------------------------------------------------------------------
// Resource groups
// -----------------------------------------------------------------------------

resource rgHub 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: names.rgHub
  location: location
  tags: tags
}

resource rgSpoke 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: names.rgSpoke
  location: location
  tags: tags
}

resource rgMgmt 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: names.rgMgmt
  location: location
  tags: tags
}

// -----------------------------------------------------------------------------
// Management — Log Analytics workspace (central monitoring sink)
// -----------------------------------------------------------------------------

module monitoring 'modules/monitoring.bicep' = {
  scope: rgMgmt
  name: 'dpl-monitoring'
  params: {
    name: names.law
    location: location
    tags: tags
  }
}

// -----------------------------------------------------------------------------
// Hub — network, firewall (central egress), bastion, VPN gateway
// -----------------------------------------------------------------------------

module hubNetwork 'modules/hub-network.bicep' = {
  scope: rgHub
  name: 'dpl-hub-network'
  params: {
    name: names.hubVnet
    location: location
    tags: tags
    addressPrefix: hubAddressSpace
    firewallSubnetPrefix: hubSubnets.firewall
    bastionSubnetPrefix: hubSubnets.bastion
    gatewaySubnetPrefix: hubSubnets.gateway
  }
}

module firewall 'modules/firewall.bicep' = {
  scope: rgHub
  name: 'dpl-firewall'
  params: {
    firewallName: names.firewall
    policyName: names.firewallPolicy
    location: location
    tags: tags
    virtualNetworkResourceId: hubNetwork.outputs.resourceId
    logAnalyticsWorkspaceResourceId: monitoring.outputs.resourceId
    allowedSpokeCidr: spokeAddressSpace
  }
}

module bastion 'modules/bastion.bicep' = {
  scope: rgHub
  name: 'dpl-bastion'
  params: {
    name: names.bastion
    location: location
    tags: tags
    virtualNetworkResourceId: hubNetwork.outputs.resourceId
    logAnalyticsWorkspaceResourceId: monitoring.outputs.resourceId
  }
}

module vpnGateway 'modules/vpn-gateway.bicep' = if (deployVpnGateway) {
  scope: rgHub
  name: 'dpl-vpn-gateway'
  params: {
    name: names.vpnGateway
    location: location
    tags: tags
    virtualNetworkResourceId: hubNetwork.outputs.resourceId
  }
}

// -----------------------------------------------------------------------------
// Spoke — workload network (peered to hub, default route to firewall)
// -----------------------------------------------------------------------------

module spokeNetwork 'modules/spoke-network.bicep' = {
  scope: rgSpoke
  name: 'dpl-spoke-network'
  params: {
    name: names.spokeVnet
    location: location
    tags: tags
    addressPrefix: spokeAddressSpace
    workloadSubnetPrefix: spokeSubnets.workload
    privateEndpointSubnetPrefix: spokeSubnets.privateEndpoints
    appGatewaySubnetPrefix: spokeSubnets.appGateway
    loadBalancerSubnetPrefix: spokeSubnets.loadBalancer
    firewallPrivateIp: firewall.outputs.privateIp
  }
}

// Bidirectional VNet peering (one peering resource lives in each resource group).
module peeringHubToSpoke 'modules/peering.bicep' = {
  scope: rgHub
  name: 'dpl-peering-hub-to-spoke'
  params: {
    localVnetName: names.hubVnet
    remoteVnetResourceId: spokeNetwork.outputs.resourceId
    peeringName: 'hub-to-spoke'
    allowGatewayTransit: deployVpnGateway
    useRemoteGateways: false
  }
}

module peeringSpokeToHub 'modules/peering.bicep' = {
  scope: rgSpoke
  name: 'dpl-peering-spoke-to-hub'
  params: {
    localVnetName: names.spokeVnet
    remoteVnetResourceId: hubNetwork.outputs.resourceId
    peeringName: 'spoke-to-hub'
    allowGatewayTransit: false
    useRemoteGateways: deployVpnGateway
  }
}

// -----------------------------------------------------------------------------
// Private DNS — zones for the private PaaS endpoints, linked to both VNets
// -----------------------------------------------------------------------------

module privateDns 'modules/private-dns.bicep' = {
  scope: rgSpoke
  name: 'dpl-private-dns'
  params: {
    tags: tags
    hubVnetResourceId: hubNetwork.outputs.resourceId
    spokeVnetResourceId: spokeNetwork.outputs.resourceId
  }
}

// -----------------------------------------------------------------------------
// Private PaaS — Key Vault & Storage, reachable only via Private Endpoints
// -----------------------------------------------------------------------------

module keyVault 'modules/key-vault.bicep' = {
  scope: rgSpoke
  name: 'dpl-key-vault'
  params: {
    name: names.keyVault
    location: location
    tags: tags
    privateEndpointSubnetResourceId: spokeNetwork.outputs.privateEndpointSubnetResourceId
    privateDnsZoneResourceId: privateDns.outputs.keyVaultZoneResourceId
    logAnalyticsWorkspaceResourceId: monitoring.outputs.resourceId
  }
}

module storage 'modules/storage.bicep' = {
  scope: rgSpoke
  name: 'dpl-storage'
  params: {
    name: names.storage
    location: location
    tags: tags
    privateEndpointSubnetResourceId: spokeNetwork.outputs.privateEndpointSubnetResourceId
    blobPrivateDnsZoneResourceId: privateDns.outputs.blobZoneResourceId
  }
}

// -----------------------------------------------------------------------------
// Private compute + internal load balancer
// -----------------------------------------------------------------------------

module loadBalancer 'modules/load-balancer.bicep' = {
  scope: rgSpoke
  name: 'dpl-load-balancer'
  params: {
    name: names.ilb
    location: location
    tags: tags
    subnetResourceId: spokeNetwork.outputs.loadBalancerSubnetResourceId
    privateIpAddress: ilbPrivateIp
  }
}

module compute 'modules/compute.bicep' = {
  scope: rgSpoke
  name: 'dpl-compute'
  params: {
    name: names.vm
    location: location
    tags: tags
    adminUsername: adminUsername
    adminSshPublicKey: adminSshPublicKey
    vmSize: vmSize
    subnetResourceId: spokeNetwork.outputs.workloadSubnetResourceId
  }
}

// -----------------------------------------------------------------------------
// Application Gateway + WAF (regional L7 ingress to the spoke)
// -----------------------------------------------------------------------------

module appGateway 'modules/app-gateway.bicep' = {
  scope: rgSpoke
  name: 'dpl-app-gateway'
  params: {
    name: names.appGateway
    wafPolicyName: names.appGwWafPolicy
    location: location
    tags: tags
    subnetResourceId: spokeNetwork.outputs.appGatewaySubnetResourceId
    backendIpAddress: ilbPrivateIp
    logAnalyticsWorkspaceResourceId: monitoring.outputs.resourceId
  }
}

// -----------------------------------------------------------------------------
// Azure Front Door + WAF (global secure delivery)
// -----------------------------------------------------------------------------

module frontDoor 'modules/front-door.bicep' = if (deployFrontDoor) {
  scope: rgSpoke
  name: 'dpl-front-door'
  params: {
    name: names.frontDoor
    wafPolicyName: names.frontDoorWafPolicy
    tags: tags
    originHostName: appGateway.outputs.frontendFqdn
    logAnalyticsWorkspaceResourceId: monitoring.outputs.resourceId
  }
}

// -----------------------------------------------------------------------------
// Observability — Network Watcher + NSG flow logs
// -----------------------------------------------------------------------------

module flowLogs 'modules/network-watcher.bicep' = if (deployNetworkWatcher) {
  scope: rgMgmt
  name: 'dpl-network-watcher'
  params: {
    location: location
    tags: tags
    flowLogsStorageName: names.flowLogsStorage
    targetNsgResourceId: spokeNetwork.outputs.workloadNsgResourceId
    logAnalyticsWorkspaceResourceId: monitoring.outputs.resourceId
  }
}

// -----------------------------------------------------------------------------
// Governance — subscription budget + alerts (cost guardrail)
// -----------------------------------------------------------------------------

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = if (!empty(budgetContactEmails)) {
  name: '${namePrefix}-budget-${regionToken}'
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
    }
    notifications: {
      Actual_GreaterThan_80_Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        contactEmails: budgetContactEmails
        thresholdType: 'Actual'
      }
      Forecast_GreaterThan_100_Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        contactEmails: budgetContactEmails
        thresholdType: 'Forecasted'
      }
    }
  }
}

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

output hubResourceGroupName string = rgHub.name
output spokeResourceGroupName string = rgSpoke.name
output mgmtResourceGroupName string = rgMgmt.name
output hubVnetResourceId string = hubNetwork.outputs.resourceId
output spokeVnetResourceId string = spokeNetwork.outputs.resourceId
output firewallPrivateIp string = firewall.outputs.privateIp
output logAnalyticsWorkspaceResourceId string = monitoring.outputs.resourceId
output keyVaultResourceId string = keyVault.outputs.resourceId
output storageAccountResourceId string = storage.outputs.resourceId
output applicationGatewayFqdn string = appGateway.outputs.frontendFqdn
output frontDoorEndpointHostName string = deployFrontDoor ? (frontDoor.?outputs.endpointHostName ?? '') : ''
