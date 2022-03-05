resource dnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: dnsName
  location: 'global'
}


resource privateDnsZonesLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: dnsZone
  name: 'dns-link'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource dnsRecordSoa 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: dnsZone
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

resource dnsRecordJumpbox 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: dnsZone
  name: 'jumpbox'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: '0.0.0.0'
      }
    ]
  }
}
