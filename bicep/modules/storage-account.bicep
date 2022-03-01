@description('Base name for the storage account.')
param name string = resourceGroup().name

@description('Location for the storage account.')
param location string = resourceGroup().location

@description('Use storage account on private network.')
param usePrivateEndpoint bool = false

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageAccountSku string = 'Standard_RAGRS'

var storageAccountName = toLower(take(replace(replace(name, '-', ''), '_', ''), 24))

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  kind: 'StorageV2'
  location: location
  sku: {
    name: storageAccountSku
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    networkAcls: usePrivateEndpoint ? {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    } : null
  }
}

output storageAccountName string = storageAccount.name
