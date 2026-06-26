// Application Gateway v2 with an attached WAF policy (OWASP), public L7 ingress.
metadata description = 'WAF_v2 Application Gateway routing to the internal load balancer backend.'

@description('Application Gateway name.')
param name string

@description('WAF policy name.')
param wafPolicyName string

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Application Gateway subnet resource ID.')
param subnetResourceId string

@description('Backend IP address (the internal load balancer frontend).')
param backendIpAddress string

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceResourceId string

// Deterministic public DNS label so Front Door has a stable origin host name.
var dnsLabel = toLower('${name}-${uniqueString(resourceGroup().id)}')
var frontendFqdn = '${dnsLabel}.${location}.cloudapp.azure.com'

// Self-referential resource ID used to wire listeners/rules to sub-resources.
var agwResourceId = resourceId('Microsoft.Network/applicationGateways', name)

module publicIp 'br/public:avm/res/network/public-ip-address:0.12.0' = {
  name: 'agw-pip-${uniqueString(name)}'
  params: {
    name: '${name}-pip'
    location: location
    tags: tags
    skuName: 'Standard'
    publicIPAllocationMethod: 'Static'
    availabilityZones: [
      1
      2
      3
    ]
    dnsSettings: {
      domainNameLabel: dnsLabel
    }
  }
}

// OWASP 3.2 WAF policy in Prevention mode.
resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-05-01' = {
  name: wafPolicyName
  location: location
  tags: tags
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
  }
}

module appGateway 'br/public:avm/res/network/application-gateway:0.9.0' = {
  name: 'agw-${uniqueString(name)}'
  params: {
    name: name
    location: location
    tags: tags
    sku: 'WAF_v2'
    capacity: 1
    firewallPolicyResourceId: wafPolicy.id
    availabilityZones: [
      1
      2
      3
    ]
    gatewayIPConfigurations: [
      {
        name: 'appGwIpConfig'
        properties: {
          subnet: {
            id: subnetResourceId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'public'
        properties: {
          publicIPAddress: {
            id: publicIp.outputs.resourceId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'workloadPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: backendIpAddress
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpSetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          pickHostNameFromBackendAddress: false
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: {
            id: '${agwResourceId}/frontendIPConfigurations/public'
          }
          frontendPort: {
            id: '${agwResourceId}/frontendPorts/port80'
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'routingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: '${agwResourceId}/httpListeners/httpListener'
          }
          backendAddressPool: {
            id: '${agwResourceId}/backendAddressPools/workloadPool'
          }
          backendHttpSettings: {
            id: '${agwResourceId}/backendHttpSettingsCollection/httpSetting'
          }
        }
      }
    ]
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
      }
    ]
  }
}

@description('Application Gateway resource ID.')
output resourceId string = appGateway.outputs.resourceId

@description('Public FQDN of the Application Gateway frontend (Front Door origin).')
output frontendFqdn string = frontendFqdn
