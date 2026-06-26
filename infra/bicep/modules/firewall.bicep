// Azure Firewall Premium + Firewall Policy providing central egress, IDPS and segmentation.
metadata description = 'Premium Azure Firewall with an IDPS-enabled policy that allows controlled spoke egress.'

@description('Firewall name.')
param firewallName string

@description('Firewall policy name.')
param policyName string

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Hub VNet resource ID (the firewall is placed in its AzureFirewallSubnet).')
param virtualNetworkResourceId string

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceResourceId string

@description('Spoke CIDR allowed outbound through the firewall.')
param allowedSpokeCidr string

module policy 'br/public:avm/res/network/firewall-policy:0.3.5' = {
  name: 'afw-policy-${uniqueString(policyName)}'
  params: {
    name: policyName
    location: location
    tags: tags
    tier: 'Premium'
    // Premium-only IDPS in Deny mode: blocks traffic matching known attack signatures
    // (PSD2 Art. 95 network anomaly detection). Benign lab HTTP/HTTPS is unaffected —
    // IDPS only acts on signature-matched exploits/malware, not normal traffic.
    // TLS inspection is design-only: it requires a customer intermediate CA certificate
    // provisioned to Key Vault.
    intrusionDetection: {
      mode: 'Deny'
    }
    ruleCollectionGroups: [
      {
        name: 'DefaultEgressRuleCollectionGroup'
        priority: 500
        ruleCollections: [
          {
            name: 'Allow-Spoke-Web-Egress'
            priority: 1000
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            action: {
              type: 'Allow'
            }
            rules: [
              {
                ruleType: 'NetworkRule'
                name: 'allow-spoke-https-http'
                ipProtocols: [
                  'TCP'
                ]
                sourceAddresses: [
                  allowedSpokeCidr
                ]
                destinationAddresses: [
                  '*'
                ]
                destinationPorts: [
                  '80'
                  '443'
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}

module firewall 'br/public:avm/res/network/azure-firewall:0.10.1' = {
  name: 'afw-${uniqueString(firewallName)}'
  params: {
    name: firewallName
    location: location
    tags: tags
    azureSkuTier: 'Premium'
    virtualNetworkResourceId: virtualNetworkResourceId
    firewallPolicyId: policy.outputs.resourceId
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
      }
    ]
  }
}

@description('Private IP of the firewall (default route next hop for spokes).')
output privateIp string = firewall.outputs.privateIp

@description('Firewall resource ID.')
output resourceId string = firewall.outputs.resourceId
