@description('Location for the vm.')
param location string = resourceGroup().location

@description('Base name for the vm.')
param name string = resourceGroup().name

@description('User name for the vm.')
param adminUserName string = 'sampleAdmin'

@description('Public SSH key for the vm.')
param publicSshKey string

@description('DNS label prefix for the vm.')
param dnsLabelPrefix string

@description('Subnet ID for the vm.')
param subnetId string

@description('Network Sercurity Group Id for the vm.')
param networkSercurityGroupId string

var vmName = name
var vmSize = 'Standard_D2s_v3'
var nicName = '${name}-nic'
var publicIPAddressName = '${name}-publicIpAddress'

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
            id: subnetId
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSercurityGroupId
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
