@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

var dnsLabelPrefix = toLower(name)
var addressPrefix = '10.0.0.0/16'
var virtualNetworkName = name
var networkSecurityGroupName = '${name}-nsgAllowRemoting'

var subnetName = '${name}-subnet'
// var subnetPrefix = '10.0.0.0/24'

var subnets = [
  {
    name: '${subnetName}-0'
    properties: {
      addressPrefix: '10.0.0.0/24'
    }
  }
  {
    name: '${subnetName}-1'
    properties: {
      addressPrefix: '10.0.1.0/24'
    }
  }
]

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-03-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'RemoteConnection'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-03-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: subnets
  }
}


resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${name}.com'
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


output subnets array = virtualNetwork.properties.subnets
output dnsLabelPrefix string = dnsLabelPrefix
output networkSercurityGroupId string = networkSecurityGroup.id
