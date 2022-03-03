@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

@description('DNS name')
param dnsName string = 'csedemos.com'

var dnsLabelPrefix = toLower(name)
var addressPrefix = '10.0.0.0/16'
var networkSecurityGroupName = '${name}-nsg'
var subnetName = '${name}-subnet'


resource jumpboxASG 'Microsoft.Network/applicationSecurityGroups@2021-05-01' = {
  name: 'jumpboxASG'
  location: location
  properties: {}
}

resource backendASG 'Microsoft.Network/applicationSecurityGroups@2021-05-01' = {
  name: 'backendASG'
  location: location
  properties: {}
}

var subnets = [
  {
    name: '${subnetName}-jumpbox'
    properties: {
      addressPrefix: '10.0.0.0/24'
      networkSecurityGroup: {
        id: jumpboxNsg.id
      }
    }
  }
  {
    name: '${subnetName}-backend'
    properties: {
      addressPrefix: '10.0.1.0/24'
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      networkSecurityGroup: {
        id: backendNsg.id
      }
    }
  }
]

resource jumpboxNsg 'Microsoft.Network/networkSecurityGroups@2020-03-01' = {
  name: '${networkSecurityGroupName}-jumpbox'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SshConnection'
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

resource backendNsg 'Microsoft.Network/networkSecurityGroups@2020-03-01' = {
  name: '${networkSecurityGroupName}-backend'
  location: location
  properties: {
    securityRules: [
      {
        name: 'JumpboxSshConnection'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceApplicationSecurityGroups: [
            {
              id: jumpboxASG.id
              location: jumpboxASG.location
            }
          ]
          destinationApplicationSecurityGroups: [
            {
              id: backendASG.id
              location: backendASG.location
            }
          ]
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        // Come back to this, need to lock down resources 
        name: 'DenyOutboundSsh'
        properties: {
          description: 'Deny SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 110
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-03-01' = {
  name: name
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

resource dnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: dnsName
  location: 'global'
}


resource privateDnsZonesLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: dnsZone
  name: 'dns-link'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

// This is not needed but keeping around to show defaults
//
// resource dnsRecordSoa 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
//   parent: dnsZone
//   name: '@'
//   properties: {
//     ttl: 3600
//     soaRecord: {
//       email: 'azureprivatedns-host.microsoft.com'
//       expireTime: 2419200
//       host: 'azureprivatedns.net'
//       minimumTtl: 10
//       refreshTime: 3600
//       retryTime: 300
//       serialNumber: 1
//     }
//   }
// }


// Keeping this here for reference on how to create a record 
//
// resource dnsRecordJumpbox 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
//   parent: dnsZone
//   name: 'jumpbox'
//   properties: {
//     ttl: 3600
//     aRecords: [
//       {
//         ipv4Address: '0.0.0.0'
//       }
//     ]
//   }
// }

output virtualNetworkName string = virtualNetwork.name
output subnets array = virtualNetwork.properties.subnets
output dnsLabelPrefix string = dnsLabelPrefix
output jumpboxNsgId string = jumpboxNsg.id
output backendNsgId string = backendNsg.id
output jumpboxASGId string = jumpboxASG.id
output backendASGId string = backendASG.id
