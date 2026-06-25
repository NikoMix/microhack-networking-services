// Private Linux VM (no public IP) — admin access only via Bastion.
metadata description = 'Ubuntu VM with system-assigned identity and SSH-key auth, no public IP.'

@description('VM name.')
param name string

@description('Deployment region.')
param location string

@description('Resource tags.')
param tags object

@description('Admin username.')
param adminUsername string

@description('SSH public key (OpenSSH). Leave empty only for build/validation; required to deploy.')
param adminSshPublicKey string

@description('VM size.')
param vmSize string

@description('Workload subnet resource ID.')
param subnetResourceId string

module vm 'br/public:avm/res/compute/virtual-machine:0.22.2' = {
  name: 'vm-${uniqueString(name)}'
  params: {
    name: name
    location: location
    tags: tags
    osType: 'Linux'
    vmSize: vmSize
    adminUsername: adminUsername
    disablePasswordAuthentication: true
    encryptionAtHost: false
    availabilityZone: -1
    managedIdentities: {
      systemAssigned: true
    }
    publicKeys: empty(adminSshPublicKey)
      ? []
      : [
          {
            keyData: adminSshPublicKey
            path: '/home/${adminUsername}/.ssh/authorized_keys'
          }
        ]
    imageReference: {
      publisher: 'Canonical'
      offer: '0001-com-ubuntu-server-jammy'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    osDisk: {
      diskSizeGB: 128
      caching: 'ReadWrite'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    nicConfigurations: [
      {
        nicSuffix: '-nic-01'
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: subnetResourceId
          }
        ]
      }
    ]
  }
}

@description('VM resource ID.')
output resourceId string = vm.outputs.resourceId

@description('VM system-assigned principal ID.')
output systemAssignedMIPrincipalId string = vm.outputs.?systemAssignedMIPrincipalId ?? ''
