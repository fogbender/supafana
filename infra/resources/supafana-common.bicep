param location string = resourceGroup().location
param sharedImageGalleryName string = 'supafanasig'
param containerRegistryName string = 'supafanacr'
param containerRegistrySku string = 'Basic'

// Shared image gallery
resource sig 'Microsoft.Compute/galleries@2023-07-03' = {
  name: sharedImageGalleryName
  location: location
  properties: {
    description: 'Private shared images for Supafana VMs'
  }
}

// Container registry
resource cr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: containerRegistrySku
  }
  properties: {
    adminUserEnabled: false
  }
}

// Prod Dns zone
resource prodDnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: 'supafana.com'
  location: 'global'
}

// Test Dns zone
resource testDnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: 'supafana-test.com'
  location: 'global'
}

output containerRegistryLoginServer string = cr.properties.loginServer

output prodNameServers array = prodDnsZone.properties.nameServers
output testNameServers array = testDnsZone.properties.nameServers
