// Azure Front Door Premium + WAF for global, secure application delivery,
// reaching the Application Gateway origin privately via Private Link.
metadata description = 'Front Door Premium profile with an endpoint, Private Link origin group and managed + custom WAF security policy.'

@description('Front Door profile name.')
param name string

@description('Front Door WAF policy name.')
param wafPolicyName string

@description('Resource tags.')
param tags object

@description('Origin host name (the Application Gateway public FQDN, used as host header).')
param originHostName string

@description('Resource ID of the Private Link target origin (the Application Gateway).')
param originPrivateLinkResourceId string

@description('Private Link group id (the Application Gateway frontend IP configuration name).')
param originPrivateLinkGroupId string

@description('Region of the Private Link origin (must match the Application Gateway region).')
param originPrivateLinkLocation string

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceResourceId string

var endpointName = '${name}-ep'
var originGroupName = 'default-origin-group'
// Resource ID of the endpoint the WAF security policy is associated with.
var afdEndpointResourceId = resourceId('Microsoft.Cdn/profiles/afdEndpoints', name, endpointName)

// Front Door Premium WAF policy. Premium adds Microsoft-managed rule sets
// (Default Rule Set + Bot Manager) on top of the rate-limit custom rule.
resource frontDoorWaf 'Microsoft.Network/frontDoorWebApplicationFirewallPolicies@2024-02-01' = {
  name: wafPolicyName
  location: 'Global'
  tags: tags
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
          ruleSetAction: 'Block'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
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
    sku: 'Premium_AzureFrontDoor'
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
            // Premium-only: reach the Application Gateway over Private Link. The
            // connection lands as "Pending" and must be approved on the App
            // Gateway side post-deploy (see the deploy script approval step).
            sharedPrivateLinkResource: {
              privateLink: {
                id: originPrivateLinkResourceId
              }
              groupId: originPrivateLinkGroupId
              privateLinkLocation: originPrivateLinkLocation
              requestMessage: 'Front Door Premium private link to the CFS Application Gateway'
            }
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
