@description('Location for the virtual machine.')
param location string = resourceGroup().location

@description('Base name for the virtual machine.')
param name string = resourceGroup().name

@description('User name for the virtual machine  (Optional: default "azure-user").')
param adminUserName string = 'azure-user'

@description('Public SSH key for the virtual machine.')
param publicSshKey string

@description('DNS label prefix for the virtual machine (Optional).  If not provided the virtual machine will not have a public IP address.')
param dnsLabelPrefix string = ''

@description('Subnet ID for the virtual machine.')
param subnetId string

@description('Network Sercurity Group Id for the virtual machine (Optional).')
param networkSercurityGroupId string = ''

var deployPublicIpAddress = !empty(dnsLabelPrefix)

var virtualMachineName = name
var virtualMachineSize = 'Standard_B1s'
var networkInterfaceName = '${name}-networkInterface'
var publicIPAddressName = '${name}-publicIpAddress'

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2020-03-01' = if (deployPublicIpAddress) {
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
          publicIPAddress: !deployPublicIpAddress ? null : {
            id: publicIPAddress.id
          }
        }
      }
    ]
    networkSecurityGroup: empty(networkSercurityGroupId) ? null : {
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

output hostname string = deployPublicIpAddress ? publicIPAddress.properties.dnsSettings.fqdn : 'NA'
