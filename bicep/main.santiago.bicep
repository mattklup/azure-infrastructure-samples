param location string = resourceGroup().location

param virtualNetworkName string = 'hub-vnet'

param addressPrefixes array = array('10.0.0.0/16')

param mainSubnetPrefix string = '10.0.0.0/24'

param firewallName string = 'hub-vnet-firewall'

param firewallSubnetAddressSpace string = '10.0.1.0/24'

param publicIpAddressForFirewall string = 'hub-vnet-firewall-ip'

param bastionName string = 'hub-vnet-bastion'

param bastionSubnetAddressSpace string = '10.0.2.0/24'

param publicIpAddressForBastion string = 'hub-vnet-bastion-ip'

resource virtualNetworkName_resource 'Microsoft.Network/VirtualNetworks@2021-01-01' = {
  name: virtualNetworkName

  location: location

  tags: {}

  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefixes
      ]
    }

    subnets: [
      {
        name: 'main'

        properties: {
          addressPrefix: mainSubnetPrefix
        }
      }

      {
        name: 'AzureFirewallSubnet'

        properties: {
          addressPrefix: firewallSubnetAddressSpace
        }
      }

      {
        name: 'AzureBastionSubnet'

        properties: {
          addressPrefix: bastionSubnetAddressSpace
        }
      }
    ]
  }

  dependsOn: []
}

resource publicIpAddress_resource 'Microsoft.Network/publicIpAddresses@2019-02-01' = {
  name: publicIpAddressForFirewall

  location: location

  sku: {
    name: 'Standard'
  }

  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallName_resource 'Microsoft.Network/azureFirewalls@2019-04-01' = {
  name: firewallName

  location: location

  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'

        properties: {
          subnet: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AzureFirewallSubnet')
          }

          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', publicIpAddressForFirewall)
          }
        }
      }
    ]
  }
}

resource publicIpAddressForBastion_resource 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: publicIpAddressForBastion

  location: location

  sku: {
    name: 'Standard'
  }

  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionName_resource 'Microsoft.Network/bastionHosts@2019-04-01' = {
  name: bastionName

  location: location

  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'

        properties: {
          subnet: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'AzureBastionSubnet')
          }

          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', publicIpAddressForBastion)
          }
        }
      }
    ]
  }
}
