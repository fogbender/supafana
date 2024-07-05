param location string = resourceGroup().location
param virtualNetworkName string = 'vNet'
param privateDnsZoneName string = 'supafana.local'
param addressPrefix string = '10.5.0.0/16'
param supafanaSubnetName string = 'SupafanaSubnet'
param supafanaSubnetAddressPrefix string = '10.5.0.0/24'
param grafanaSubnetName string = 'GrafanaSubnet'
param grafanaSubnetAddressPrefix string = '10.5.16.0/20'

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: supafanaSubnetName
        properties: {
          addressPrefix: supafanaSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: grafanaSubnetName
        properties: {
          addressPrefix: grafanaSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

// DNS Zone Link
resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${virtualNetworkName}-link'
  location: 'global'
  parent: privateDnsZone
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: true
  }
}

output vnetId string = vnet.id
output supafanaSubnetId string = vnet.properties.subnets[0].id
output grafanaSubnetId string = vnet.properties.subnets[1].id
