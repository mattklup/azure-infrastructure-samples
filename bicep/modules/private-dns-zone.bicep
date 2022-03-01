@description('Existing virtual network name.')
param virtualNetworkName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-03-01' existing = {
  name: virtualNetworkName
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${virtualNetworkName}.com'
  location: 'global'
  properties: {
  }
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${virtualNetwork.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}
