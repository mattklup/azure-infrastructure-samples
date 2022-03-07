@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

var sanitizedName = replace(replace(name, '-', ''), '_', '')
var suffix = take(toLower(uniqueString(resourceGroup().id, location)), 6)

module network 'networking/networking.bicep' = {
  name: 'network'
  params: {
    name: name
    location: location
  }
}

module identity 'networking/identity.bicep' = {
  name: 'identity'
  params: {
    location: location
  }
}

module appStorage 'networking/storage.bicep' = {
  name: 'appStorage'
  params: {
    storageAccountName: '${sanitizedName}app${suffix}'
    location: location
    subnetId: network.outputs.backendSubnetId
    asgId: network.outputs.appStorageASGId
    privateDnsZoneId: network.outputs.blobPrivateDnsZoneId
    writers: [
      identity.outputs.jumpboxIdentityPrincipalId
    ]
    readers: [
      identity.outputs.backendVmIdentityPrincipalId
    ]
  }
}
