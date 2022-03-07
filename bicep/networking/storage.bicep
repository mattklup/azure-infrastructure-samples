
@description('Name of the storage account')
param storageAccountName string

@description('resource id for the subnet that the storage account should be exposed to')
param subnetId string

@description('resource id of the ApplicationSecurityGroup that the blob private endpoint should be a member of')
param asgId string

@description('resource id of the private DNS zone that the blob private endpoint should be registered with')
param privateDnsZoneId string

@description('principal ids that will be granted the Storage Blob Data Contributor role')
param writers array = []

@description('principal ids that will be granted the Storage Blob Data Reader role')
param readers array = []

param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  kind: 'StorageV2'
  location: location
  name: storageAccountName
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
    publicNetworkAccess: 'Disabled'
    supportsHttpsTrafficOnly: true
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${storageAccountName}-blob'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'blob'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    applicationSecurityGroups: [
      {
        id: asgId
      }
    ]
  }
}

resource privateEndpointDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: privateEndpoint
  name: 'blobPrivateDns'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: resourceGroup().name
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
// 'Storage Blob Data Contributor' built-in role
resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2015-07-01' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource writerAssignments 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for principalId in writers: {
  name: guid(principalId, storageAccount.id, storageBlobDataContributor.id)
  scope: storageAccount
  properties: {
    principalType: 'ServicePrincipal'
    principalId: principalId
    roleDefinitionId: storageBlobDataContributor.id
  }
}]

// 'Storage Blob Data Reader' built-in role
resource storageBlobDataReader 'Microsoft.Authorization/roleDefinitions@2015-07-01' existing = {
  scope: subscription()
  name: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
}

resource readerAssignments 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for principalId in readers: {
  name: guid(principalId, storageAccount.id, storageBlobDataReader.id)
  scope: storageAccount
  properties: {
    principalType: 'ServicePrincipal'
    principalId: principalId
    roleDefinitionId: storageBlobDataReader.id
  }
}]
