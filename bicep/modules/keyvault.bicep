@description('Base name for the keyvault.')
param name string

@description('Location for the storage account.')
param location string

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: name
  location: location
  tags: {
    lock: 'CHANGE_THIS_TO_DND_LATER'
  }
  properties: {
    enabledForDeployment: true
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableSoftDelete: false
    tenantId: subscription().tenantId
  }
}
