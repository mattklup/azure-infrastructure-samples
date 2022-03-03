@description('Base name for the keyvault.')
param name string

@description('Location for the storage account.')
param location string

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: name
  location: location
  tags: {
    lock: 'CHANGE_THIS_TO_DND_LATER'
  }
  properties: {
    // Azure VMs are permitted to retrieve certs stored as secrets
    enabledForDeployment: true
    // I don't think ARM needs to retrieve secrets yet
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableSoftDelete: false
    tenantId: subscription().tenantId
  }
}
