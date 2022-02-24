@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

@description('User name for the vm.')
param adminUserName string = 'sampleAdmin'

var publicSshKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAl3IlQwvKMBhI4bqTBilC3IwH7gSXNdL2sIN3j9LiObaEXHg2S4ASOkcGT9e/lN4Ux8b3bphd0G6oN2fAZR+MlrKSCVy5qAzcky0CuHzVaOUTH65oTE6ut2ReHB950oKbcpU3vHonjwaxTAyeyMGwECyxtjW7/XLnvRo35w7lhnki8yIEpESMP3wMtvHtb+C6Ff8LxmRSPacDpiQ35Dn3Iy0jNu/bgeMAMTEeMNYzcVsBgMVgwL+0QZ06/LDzTjzqpfk1W1GjeR9vl0VfjDiJP67h9cAk4BkjQPAk/1ChSlXNLdw/T1vAGCXSEhzDQoNpMo6FAk0TCcqESK1mQ5VmvvQ7XUhz4QBPaEgySfMk+WMx3YdkPayQueAvUg7MrPagqSCCX5jT5IuEitk172QO4N8zOuEg11gTMEfS9LLwhJLRVArJTjC7N8y+LeQUQ6eICj1/F44Dr2Eb7eRcz9+/z67O3n4Y9K5Y3f/L1ncSNqYaJ8nAGDGsRTyj56hwHLURPLUZDz1AyxUuUynt5e4tD1wI2VZwce5eRZ0o9HGoNX/dONDyaXY0SDucZgDjGIwxy6vXmsMO7ha0BCyGANbV3cs41mXFExIFFItl2XXgMgllxN2zU5dvLQ8zdfN+XNmWV63Z5v2zTlQqYWabiHbMq1IX1SDGfsD1j1BxCpi9ow== codespace@codespaces_aa55f7'

var dnsLabelPrefix = toLower(name)
var addressPrefix = '10.0.0.0/16'
var subnetName = '${name}-subnet'
var subnetPrefix = '10.0.0.0/24'
var vmName = name
var vmSize = 'Standard_D2s_v3'
var virtualNetworkName = name
var osType = 'Linux'
var networkSecurityGroupName = '${name}-nsgAllowRemoting'
var nicName = '${name}-nic'
var publicIPAddressName = '${name}-publicIpAddress'

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-03-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'RemoteConnection'
        properties: {
          description: 'Allow RDP/SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: ((osType == 'Windows') ? '3389' : '22')
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

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2020-03-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      //adminPassword: adminPasswordOrKey
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUserName}/.ssh/authorized_keys'
              keyData: publicSshKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output hostname string = publicIPAddress.properties.dnsSettings.fqdn
