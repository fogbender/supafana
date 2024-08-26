// Have to move dns creation to separate module, as dns zone name should
// available at compile time

param name string
param dnsZoneName string
param vnetId string

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'
  resource vNetLink 'virtualNetworkLinks' = {
    name: '${name}-vnet-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: { id: vnetId }
    }
  }
}

output privateDnsZoneId string = privateDnsZone.id
