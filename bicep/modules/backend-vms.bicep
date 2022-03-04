param location string
param backendASGId string 
param subnetId string 
param sshPublicKey string

param adminUserName string = 'azureuser'
param lbName string = 'lb'
param lbPublicIp string = 'lb-ip'
param frontendIpConfigName string = 'defaultFrontend'
param backendPoolName string = 'backendpool'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'backendVms'
  location: location
}

resource lbPublicIP 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: lbPublicIp
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'loadbalancer0123'
    }
  }
}

resource vm1 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(0, 2): {
  name: 'vm${i}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'OpenLogic'
        offer: 'CentOS'
        sku: '7_9'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: 'vm${i}'
      adminUsername: adminUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaceConfigurations: [
        {
          name: 'nic4${i}'
          properties: {
            ipConfigurations: [
              {
                name: 'ipconfig1'
                properties: {
                  subnet: {
                    id: subnetId
                  }
                  primary: true
                  applicationSecurityGroups: [
                    {
                      id: backendASGId
                    }
                  ]
                  loadBalancerBackendAddressPools: [
                    {
                      id: lb.properties.backendAddressPools[0].id
                    }
                  ]
                }
              }
            ]
            enableAcceleratedNetworking: true
            enableIPForwarding: false
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}]

resource lb 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: frontendIpConfigName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: lbPublicIP.id
          }
        }
      }
    ]
    backendAddressPools: [ 
      {
        name: backendPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: 'defaultRule'
        properties: {
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80                  
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, frontendIpConfigName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, backendPoolName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'globalLobby', 'defaultProbe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'healthprobe'
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}
