@description('Base name for the storage account.')
param name string = resourceGroup().name

@description('Location for the storage account.')
param location string = resourceGroup().location

@description('Existing virtual network name to use for a private endpoint  (Optional).')
param virtualNetworkName string = ''

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageAccountSku string = 'Standard_RAGRS'

var usePrivateEndpoint = !empty(virtualNetworkName)
var storageAccountName = toLower(take(replace(replace(name, '-', ''), '_', ''), 24))
var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-03-01' existing = if (usePrivateEndpoint) {
  name: virtualNetworkName
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (usePrivateEndpoint) {
  name: '${name}-privateEndpoint'
  location: location
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-ServiceConnection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
  }
}

resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-01-01' = if (usePrivateEndpoint) {
  name: blobPrivateDnsZoneName
  location: 'global'
}

resource blobPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (usePrivateEndpoint) {
  parent: blobPrivateDnsZone
  name: '${virtualNetwork.name}-blob-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource privateEndpointDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = if (usePrivateEndpoint) {
  name: '${privateEndpoint.name}/blob-PrivateDnsZoneGroup'
  properties:{
    privateDnsZoneConfigs: [
      {
        name: blobPrivateDnsZoneName
        properties:{
          privateDnsZoneId: blobPrivateDnsZone.id
        }
      }
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  kind: 'StorageV2'
  location: location
  sku: {
    name: storageAccountSku
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    networkAcls: usePrivateEndpoint ? {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    } : null
  }
}

output storageAccountName string = storageAccount.name
