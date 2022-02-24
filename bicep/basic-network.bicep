@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

@description('User name for the vm.')
param adminUserName string = 'sampleAdmin'

@description('Public SSH key for the vm.')
param publicSshKey string

module virtualNetworkModue 'modules/virtual-network.bicep' = {
  name: 'virtualNetwork'
  params: {
    name: name
    location: location
    adminUserName: adminUserName
    publicSshKey: publicSshKey
  }
}
