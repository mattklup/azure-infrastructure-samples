@description('Base name for the keyvault.')
param name string

@description('Location for the storage account.')
param location string

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'deployment'
  location: location
}

resource keyVaultAdministratorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483'  // Key Vault Administrator
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: name
  location: location
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

/*resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: 'keyvaultRole'
  scope: keyVault
  properties: {
    principalType: 'ServicePrincipal'
    principalId: identity.properties.principalId
    roleDefinitionId: keyVaultAdministratorRoleDefinition.id
  }
}

resource generateScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  dependsOn: [
    keyVaultRoleAssignment
  ]
  location: location
  name: 'generateSslCert'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.32.0'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'RESOURCE_GROUP'
        value: resourceGroup().name
      }
      {
        name: 'SSLCERT_NAME'
        value: name
      }
      {
        name: 'VAULT_NAME'
        value: keyVault.name
      }
    ]
    scriptContent: '''
#!/bin/bash
set -euo pipefail

az keyvault certificate create --vault-name $VAULT_NAME -n $SSLCERT_NAME -p "$(az keyvault certificate get-default-policy)"
'''
  }
}*/
