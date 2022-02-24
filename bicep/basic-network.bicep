@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

@description('User name for the vm.')
param adminUserName string = 'sampleAdmin'

@description('Public SSH key for the vm.')
param publicSshKey string

module virtualNetworkModule 'modules/virtual-network.bicep' = {
  name: 'virtualNetwork'
  params: {
    name: name
    location: location
  }
}

module virtualMachine 'modules/virtual-machine.bicep' = {
  name: 'virtualMachine'
  params: {
    name: name
    location: location
    adminUserName: adminUserName
    publicSshKey: publicSshKey
    dnsLabelPrefix: virtualNetworkModule.outputs.dnsLabelPrefix
    subnetId: virtualNetworkModule.outputs.subnetId
    networkSercurityGroupId: virtualNetworkModule.outputs.networkSercurityGroupId
  }
}
