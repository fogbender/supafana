// Creates DNS record for public ip in already existing DNS zone
// Should be called with `scope: resourceGroup('supafana-common-rg')`

param ipAddress string
param publicDomain string

var domainParts = split(publicDomain, '.')
var zoneName = length(domainParts) == 2 ? publicDomain : join([domainParts[1], domainParts[2]], '.')
var recordName = length(domainParts) == 2 ? '@' : domainParts[0]

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: zoneName
}

resource record 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: dnsZone
  name: recordName
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: ipAddress
      }
    ]
  }
}
