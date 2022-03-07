param location string = resourceGroup().location

resource jumpboxIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'jumpbox'
  location: location
}

resource backendVmIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'backendVM'
  location: location
}

output jumpboxIdentityPrincipalId string = jumpboxIdentity.properties.principalId
output backendVmIdentityPrincipalId string = backendVmIdentity.properties.principalId
