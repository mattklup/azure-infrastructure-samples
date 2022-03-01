@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

@description('User name for the vms.')
param adminUserName string = 'azure-user'

@description('Public SSH key for the vms.')
param publicSshKey string

@description('Deploy private Dns Zone.')
param deployPrivateDnsZone bool = true

@description('Deploy azure storage account.')
param deployStorageAccount bool = true

@description('Number of vms to deploy.')
var privateVmCount = 2

module virtualNetwork 'modules/virtual-network.bicep' = {
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
    dnsLabelPrefix: virtualNetwork.outputs.dnsLabelPrefix
    subnetId: virtualNetwork.outputs.subnets[0].id
    networkSercurityGroupId: virtualNetwork.outputs.networkSercurityGroupId
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
    subnetId: virtualNetwork.outputs.subnets[1].id
    networkSercurityGroupId: virtualNetwork.outputs.networkSercurityGroupId
  }
}]

module privateDnsZone 'modules/private-dns-zone.bicep' = if (deployPrivateDnsZone) {
  name: 'privateDnsZone'
  params: {
    virtualNetworkName: virtualNetwork.outputs.virtualNetworkName
  }
}

module storageAccount 'modules/storage-account.bicep' = if (deployStorageAccount) {
  name: 'storageAccount'
  params: {
    name: name
    location: location
    virtualNetworkName: virtualNetwork.outputs.virtualNetworkName
  }
}

output virtualNetworkDnsLabelPrefix string = virtualNetwork.outputs.dnsLabelPrefix
output virtualNetworkNetworkSercurityGroupId string = virtualNetwork.outputs.networkSercurityGroupId
output virtualNetworkSubnetId array = virtualNetwork.outputs.subnets
output virtualMachinesPrivate array = [for i in range(0, privateVmCount): {
  name: virtualMachinePrivate[i].name
}]
output virtualMachineJumpBox object = {
  name: virtualMachineJumpbox.name
  hostName: virtualMachineJumpbox.outputs.hostname
}

output storageAccountName string = deployStorageAccount ? storageAccount.outputs.storageAccountName : 'NA'
