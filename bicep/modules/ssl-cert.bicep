@description('Base name for the ssl certificate.')
param name string = resourceGroup().name

@description('Location for the ssl cert.')
param location string = resourceGroup().location

@description('cname for the ssl certificate')
param cname string

resource sslCert 'Microsoft.Web/certificates@2021-03-01' = {
  name: name
  location: location
  kind: 'string'
  properties: {
    canonicalName: cname
  //  domainValidationMethod: App Service Verification
    hostNames: [
      'string'
    ]
    keyVaultId: 'string'
    keyVaultSecretName: 'string'
    password: 'string'
    serverFarmId: 'string'
  }
}
