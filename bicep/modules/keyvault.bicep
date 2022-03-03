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
    enabledForTemplateDeployment: false
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 15
    tenantId: '72f988bf-86f1-41af-91ab-2d7cd011db47'
  }
}
