@description('Location for the network.')
param location string = resourceGroup().location

@description('Base name for the network.')
param name string = resourceGroup().name

module mainNetwork 'modules/networking.bicep' = {
  name: 'mainNetwork'
  params: {
    name: name
    location: location
  }
}
