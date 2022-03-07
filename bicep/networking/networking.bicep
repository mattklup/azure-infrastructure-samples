@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

@description('DNS name')
param dnsName string = 'csedemos.com'

// TODO: don't embed resource types in names
var networkSecurityGroupName = '${name}-nsg'
var subnetName = '${name}-subnet'
var jumpboxSubnetName = '${subnetName}-jumpbox'
var backendSubnetName = '${subnetName}-backend'


resource jumpboxASG 'Microsoft.Network/applicationSecurityGroups@2021-05-01' = {
  name: 'jumpboxASG'
  location: location
}

resource backendASG 'Microsoft.Network/applicationSecurityGroups@2021-05-01' = {
  name: 'backendASG'
  location: location
}

resource appStorageASG 'Microsoft.Network/applicationSecurityGroups@2021-05-01' = {
  name: 'appStorage'
  location: location
}

resource jumpboxNsg 'Microsoft.Network/networkSecurityGroups@2020-03-01' = {
  name: '${networkSecurityGroupName}-jumpbox'
  location: location
  properties: {
    securityRules: [
      // TODO: remove wide-open SSH
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
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBackendVMsToStorage'
        properties: {
          direction: 'Inbound'
          priority: 1010
          access: 'Allow'
          protocol: 'Tcp'
          sourceApplicationSecurityGroups: [
            {
              id: jumpboxASG.id
            }
          ]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            {
              id: appStorageASG.id
            }
          ]
          destinationPortRange: '443'
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
          direction: 'Inbound'
          priority: 1000
          access: 'Allow'
          protocol: 'Tcp'
          sourceApplicationSecurityGroups: [
            {
              id: jumpboxASG.id
            }
          ]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            {
              id: backendASG.id
            }
          ]
          destinationPortRange: '22'
        }
      }
      {
        name: 'AllowBackendVMsToStorage'
        properties: {
          direction: 'Inbound'
          priority: 1010
          access: 'Allow'
          protocol: 'Tcp'
          sourceApplicationSecurityGroups: [
            {
              id: backendASG.id
            }
          ]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            {
              id: appStorageASG.id
            }
          ]
          destinationPortRange: '443'
        }
      }
      {
        // TODO: Come back to this, need to lock down resources 
        name: 'DenyOutboundSsh'
        properties: {
          description: 'Deny SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
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
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: jumpboxSubnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: jumpboxNsg.id
          }
        }
      }
      {
        name: backendSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'    // TODO: opt-in to public preview and set to Enabled (https://azure.microsoft.com/en-us/updates/public-preview-of-private-link-network-security-group-support/)
          networkSecurityGroup: {
            id: backendNsg.id
          }
        }
      }
    ]
  }

  resource jumpboxSubnet 'subnets' existing = {
    name: jumpboxSubnetName
  }

  resource backendSubnet 'subnets' existing = {
    name: backendSubnetName
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

resource blobPrivateDns 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
}

resource blobPrivateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: blobPrivateDns
  name: virtualNetwork.name
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

output jumpboxSubnetId string = virtualNetwork::jumpboxSubnet.id
output backendSubnetId string = virtualNetwork::backendSubnet.id
output jumpboxASGId string = jumpboxASG.id
output backendASGId string = backendASG.id
output appStorageASGId string = appStorageASG.id
output blobPrivateDnsZoneId string = blobPrivateDns.id
