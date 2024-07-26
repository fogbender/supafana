param location string = resourceGroup().location
param virtualNetworkName string = 'vNet'
param privateDnsZoneName string = 'supafana.local'
param addressPrefix string = '10.5.0.0/16'
param supafanaSubnetName string = 'SupafanaSubnet'
param supafanaSubnetAddressPrefix string = '10.5.0.0/24'
param grafanaSubnetName string = 'GrafanaSubnet'
param grafanaSubnetAddressPrefix string = '10.5.16.0/20'
param dbSubnetName string = 'DbSubnet'
param dbSubnetAddressPrefix string = '10.5.1.0/24'

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
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
      {
        name: dbSubnetName
        properties: {
          addressPrefix: dbSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: '${dbSubnetName}-delegation'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
          networkSecurityGroup: { id: dbSubnetNsg.id }
        }
      }
    ]
  }
}

// Db subnet security group
resource dbSubnetNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${dbSubnetName}-security-group'
  location: location
  properties: {
    securityRules: [
      {
        name: 'db-grafana-deny-security-rule'
        properties : {
          protocol : '*'
          sourcePortRange :  '*'
          destinationPortRange :  '*'
          sourceAddressPrefix :  grafanaSubnetAddressPrefix
          destinationAddressPrefix: '*'
          access:  'Deny'
          priority : 1010
          direction : 'Inbound'
          sourcePortRanges : []
          destinationPortRanges : []
          sourceAddressPrefixes : []
          destinationAddressPrefixes : []
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

output vNetId string = vnet.id
output supafanaSubnetId string = vnet.properties.subnets[0].id
output grafanaSubnetId string = vnet.properties.subnets[1].id
output dbSubnetId string = vnet.properties.subnets[2].id
output privateDnsZoneId string = privateDnsZone.id
