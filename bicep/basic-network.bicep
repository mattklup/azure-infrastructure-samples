@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

@description('User name for the vms.')
param adminUserName string = 'sampleAdmin'

@description('Public SSH key for the vms.')
param publicSshKey string

@description('Number of vms to deploy.')
var vmCount = 2

module virtualNetworkModule 'modules/virtual-network.bicep' = {
  name: 'virtualNetwork'
  params: {
    name: name
    location: location
  }
}

module virtualMachine 'modules/virtual-machine.bicep' = [for i in range(0, vmCount): {
  name: 'virtualMachine-${i}'
  params: {
    name: '${name}-${i}'
    location: location
    adminUserName: adminUserName
    publicSshKey: publicSshKey
    dnsLabelPrefix: '${virtualNetworkModule.outputs.outputs.dnsLabelPrefix}-${i}'
    subnetId: virtualNetworkModule.outputs.outputs.subnetId
    networkSercurityGroupId: virtualNetworkModule.outputs.outputs.networkSercurityGroupId
  }
}]

output virtualNetworkDnsLabelPrefix string = virtualNetworkModule.outputs.dnsLabelPrefix
output virtualNetworkNetworkSercurityGroupId string = virtualNetworkModule.outputs.networkSercurityGroupId
output virtualNetworkSubnetId string = virtualNetworkModule.outputs.subnetId

output virtualMachines array = [for i in range(0, vmCount): virtualMachine[i]]
