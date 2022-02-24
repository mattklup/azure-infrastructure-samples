@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

var dnsLabelPrefix = toLower(name)
var addressPrefix = '10.0.0.0/16'
var subnetName = '${name}-subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = name
var networkSecurityGroupName = '${name}-nsgAllowRemoting'

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
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

output subnetId string = virtualNetwork.properties.subnets[0].id
output dnsLabelPrefix string = dnsLabelPrefix
output networkSercurityGroupId string = networkSecurityGroup.id
