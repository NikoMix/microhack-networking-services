// Azure Front Door Standard + WAF for global, secure application delivery.
metadata description = 'Front Door Standard profile with an endpoint, origin group and WAF security policy.'

@description('Front Door profile name.')
param name string

@description('Front Door WAF policy name.')
param wafPolicyName string

@description('Resource tags.')
param tags object

@description('Origin host name (the Application Gateway public FQDN).')
param originHostName string

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceResourceId string

var endpointName = '${name}-ep'
var originGroupName = 'default-origin-group'
// Resource ID of the endpoint the WAF security policy is associated with.
var afdEndpointResourceId = resourceId('Microsoft.Cdn/profiles/afdEndpoints', name, endpointName)

// Front Door WAF policy (Standard tier supports custom rules; rate-limit example).
resource frontDoorWaf 'Microsoft.Network/frontDoorWebApplicationFirewallPolicies@2024-02-01' = {
  name: wafPolicyName
  location: 'Global'
  tags: tags
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
    }
    customRules: {
      rules: [
        {
          name: 'RateLimitPerClientIp'
          priority: 1
          enabledState: 'Enabled'
          ruleType: 'RateLimitRule'
          rateLimitThreshold: 1000
          rateLimitDurationInMinutes: 1
          matchConditions: [
            {
              matchVariable: 'RequestUri'
              operator: 'Any'
              negateCondition: false
              matchValue: []
            }
          ]
          action: 'Block'
        }
      ]
    }
  }
}

module frontDoor 'br/public:avm/res/cdn/profile:0.19.3' = {
  name: 'afd-${uniqueString(name)}'
  params: {
    name: name
    location: 'global'
    tags: tags
    sku: 'Standard_AzureFrontDoor'
    managedIdentities: {
      systemAssigned: true
    }
    originGroups: [
      {
        name: originGroupName
        loadBalancingSettings: {
          additionalLatencyInMilliseconds: 50
          sampleSize: 4
          successfulSamplesRequired: 3
        }
        healthProbeSettings: {
          probePath: '/'
          probeProtocol: 'Http'
          probeRequestType: 'HEAD'
          probeIntervalInSeconds: 100
        }
        origins: [
          {
            name: 'appgw-origin'
            hostName: originHostName
            originHostHeader: originHostName
            httpPort: 80
            httpsPort: 443
            priority: 1
            weight: 1000
          }
        ]
      }
    ]
    afdEndpoints: [
      {
        name: endpointName
        routes: [
          {
            name: 'default-route'
            originGroupName: originGroupName
            supportedProtocols: [
              'Http'
              'Https'
            ]
            patternsToMatch: [
              '/*'
            ]
            forwardingProtocol: 'HttpOnly'
            linkToDefaultDomain: 'Enabled'
            httpsRedirect: 'Enabled'
          }
        ]
      }
    ]
    securityPolicies: [
      {
        name: 'waf-security-policy'
        wafPolicyResourceId: frontDoorWaf.id
        associations: [
          {
            domains: [
              {
                id: afdEndpointResourceId
              }
            ]
            patternsToMatch: [
              '/*'
            ]
          }
        ]
      }
    ]
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
      }
    ]
  }
}

@description('Front Door profile resource ID.')
output resourceId string = frontDoor.outputs.resourceId

@description('Default endpoint host name.')
output endpointHostName string = frontDoor.outputs.frontDoorEndpointHostNames[0]
