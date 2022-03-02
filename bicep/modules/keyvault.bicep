@description('Base name for the keyvault.')
param name string = resourceGroup().name

@description('Location for the storage account.')
param location string = resourceGroup().location

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: name
  location: location
  tags: {
    lock: 'CHANGE_THIS_TO_DND_LATER'
  }
  properties: {
    // This is who can access our keyvault
    /*accessPolicies: [
      {
        applicationId: 'string'
        objectId: 'string'
        permissions: {
          certificates: [
            'string'
          ]
          keys: [
            'string'
          ]
          secrets: [
            'string'
          ]
          storage: [
            'string'
          ]
        }
        tenantId: 'string'
      }
    ]
    createMode: 'string'*/
    // Azure VMs are permitted to retrieve certs stored as secrets
    enabledForDeployment: true
    // I don't think ARM needs to retrieve secrets yet
    enabledForTemplateDeployment: false
    enableRbacAuthorization: true
    /*Consider adding to this later if necessary
    networkAcls: {
      bypass: 'string'
      defaultAction: 'string'
      ipRules: [
        {
          value: 'string'
        }
      ]
      virtualNetworkRules: [
        {
          id: 'string'
          ignoreMissingVnetServiceEndpoint: bool
        }
      ]
    }*/
    //publicNetworkAccess: 'string'
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 15
    tenantId: 'tmp'
  }
}
