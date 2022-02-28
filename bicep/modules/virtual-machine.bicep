@description('Location for the virtual machine.')
param location string = resourceGroup().location

@description('Base name for the virtual machine.')
param name string = resourceGroup().name

@description('User name for the virtual machine.')
param adminUserName string = 'sampleAdmin'

@description('Public SSH key for the virtual machine.')
param publicSshKey string

@description('DNS label prefix for the virtual machine.  If not provided the virtual machine will not have a public IP address.')
param dnsLabelPrefix string = ''

@description('Subnet ID for the virtual machine.')
param subnetId string

@description('Network Sercurity Group Id for the virtual machine.')
param networkSercurityGroupId string

var depoyPublicIpAddress = !empty(dnsLabelPrefix)

var virtualMachineName = name
var virtualMachineSize = 'Standard_D2s_v3'
var networkInterfaceName = '${name}-networkInterface'
var publicIPAddressName = '${name}-publicIpAddress'

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2020-03-01' = if (depoyPublicIpAddress) {
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

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
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
          publicIPAddress: !depoyPublicIpAddress ? null : {
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

resource virtualMachine 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: virtualMachineName
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
          id: networkInterface.id
        }
      ]
    }
  }
}

output hostname string = depoyPublicIpAddress ? publicIPAddress.properties.dnsSettings.fqdn : 'NA'
