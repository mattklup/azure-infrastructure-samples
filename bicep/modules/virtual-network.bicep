@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

var dnsLabelPrefix = toLower(name)
var addressPrefix = '10.0.0.0/16'
var subnetAddressPrefixJumpbox = '10.0.0.0/24'
var subnetAddressPrefixInternal = '10.0.1.0/24'
var virtualNetworkName = name

var subnetName = '${name}-subnet'

resource networkSecurityGroupDenySshInternal 'Microsoft.Network/networkSecurityGroups@2020-03-01' = {
  name: '${name}-denySshInternal'
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenySshInVnet'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: subnetAddressPrefixInternal
          destinationAddressPrefix: subnetAddressPrefixInternal
          access: 'Deny'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource networkSecurityGroupAllowSshToJumpbox 'Microsoft.Network/networkSecurityGroups@2020-03-01' = {
  name: '${name}-allowSshToJumpbox'
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

var subnets = [
  {
    name: '${subnetName}-jumpbox'
    properties: {
      addressPrefix: subnetAddressPrefixJumpbox
      networkSecurityGroup: {
        id: networkSecurityGroupAllowSshToJumpbox.id
      }
    }
  }
  {
    name: '${subnetName}-internal'
    properties: {
      addressPrefix: subnetAddressPrefixInternal
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      networkSecurityGroup: {
        id: networkSecurityGroupDenySshInternal.id
      }
    }
  }
]

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

resource networkWatcher 'Microsoft.Network/networkWatchers@2021-05-01' = {
  name: name
  location: location
}

output virtualNetworkName string = virtualNetwork.name
output subnets array = virtualNetwork.properties.subnets
output dnsLabelPrefix string = dnsLabelPrefix
