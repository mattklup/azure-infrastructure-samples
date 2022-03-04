param location string
param keyVaultName string

resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'  // Contributor
}


resource keyVaultAdministratorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483'  // Key Vault Administrator
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(identity.id, keyVault.id, keyVaultAdministratorRoleDefinition.id)
  scope: keyVault
  properties: {
    principalType: 'ServicePrincipal'
    principalId: identity.properties.principalId
    roleDefinitionId: keyVaultAdministratorRoleDefinition.id
  }
}

resource rgRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, contributorRoleDefinition.id)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: identity.properties.principalId
    roleDefinitionId: contributorRoleDefinition.id
  }
}

resource sshKey 'Microsoft.Compute/sshPublicKeys@2021-11-01' = {
  location: location
  name: 'admin'
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'deployment'
  location: location
}

resource generateScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  dependsOn: [
    rgRoleAssignment
  ]
  location: location
  name: 'generateSSHKey'
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
        name: 'SSHKEY_NAME'
        value: sshKey.name
      }
      {
        name: 'VAULT_NAME'
        value: keyVaultName
      }
    ]
    scriptContent: '''
#!/bin/bash
set -euo pipefail
EXISTING_KEY="$(az sshkey show -g $RESOURCE_GROUP -n $SSHKEY_NAME --query publicKey -o tsv)"
if [ -z "${EXISTING_KEY}" ]; then
  echo "creating SSH private key and storing in Key Vault..."
  PRIVATE_KEY=$(az rest -m post -u "/subscriptions/{subscriptionId}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Compute/sshPublicKeys/${SSHKEY_NAME}/generateKeyPair?api-version=2021-11-01" --query privateKey -o tsv)
  az keyvault secret set --vault-name $VAULT_NAME --name "${SSHKEY_NAME}-sshPrivateKey" --value "${PRIVATE_KEY}" > /dev/null
else
  echo "private key already exists on sshPublicKey resource, skipping..."
fi
az sshkey show -g $RESOURCE_GROUP -n $SSHKEY_NAME --query '{publicKey:publicKey}' > $AZ_SCRIPTS_OUTPUT_PATH
'''
  }
}

output sshPublicKey string = generateScript.properties.outputs.publicKey
