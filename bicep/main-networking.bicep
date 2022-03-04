@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

module mainNetwork 'modules/networking.bicep' = {
  name: 'mainNetwork'
  params: {
    name: name
    location: location
  }
}

module keyVault 'modules/keyvault.bicep' = {
  scope: resourceGroup()
  name: 'keyVault'
  params: {
    location: location
    name: 'krakenKeyVault0123'
  }
}

module sshKey 'modules/sshKey.bicep' = {
  scope: resourceGroup()
  name: 'sshKey'
  params: {
    location: location
    keyVaultName: keyVault.outputs.name
  }
}

module backendVms 'modules/backend-vms.bicep' = {
  name: 'backendVms'
  params: {
    location: location
    backendASGId: mainNetwork.outputs.backendASGId
    subnetId: mainNetwork.outputs.backendSubnetId
    sshPublicKey: sshKey.outputs.sshPublicKey
  }
}

