@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

@description('User name for the vms.')
param adminUserName string = 'sampleAdmin'

@description('Public SSH key for the vms.')
param publicSshKey string

@description('Number of vms to deploy.')
var privateVmCount = 2

module virtualNetworkModule 'modules/virtual-network.bicep' = {
  name: 'virtualNetwork'
  params: {
    name: name
    location: location
  }
}

// jumpbox
module virtualMachineJumpbox 'modules/virtual-machine.bicep' = {
  name: 'virtualMachine-jumpbox'
  params: {
    name: '${name}-jumpbox'
    location: location
    adminUserName: adminUserName
    publicSshKey: publicSshKey
    dnsLabelPrefix: virtualNetworkModule.outputs.dnsLabelPrefix
    subnetId: virtualNetworkModule.outputs.subnets[0].id
    networkSercurityGroupId: virtualNetworkModule.outputs.networkSercurityGroupId
  }
}

// private vms
module virtualMachinePrivate 'modules/virtual-machine.bicep' = [for i in range(0, privateVmCount): {
  name: 'virtualMachine-${i}'
  params: {
    name: '${name}-${i}'
    location: location
    adminUserName: adminUserName
    publicSshKey: publicSshKey
    dnsLabelPrefix: ''
    subnetId: virtualNetworkModule.outputs.subnets[1].id
    networkSercurityGroupId: virtualNetworkModule.outputs.networkSercurityGroupId
  }
}]

/*
output virtualNetworkDnsLabelPrefix string = virtualNetworkModule.outputs.dnsLabelPrefix
output virtualNetworkNetworkSercurityGroupId string = virtualNetworkModule.outputs.networkSercurityGroupId
output virtualNetworkSubnetId array = virtualNetworkModule.outputs.subnets
output virtualMachines array = [for i in range(0, vmCount): {
  name: virtualMachine[i].name
  hostName: virtualMachine[i].outputs.hostname
}]
*/
