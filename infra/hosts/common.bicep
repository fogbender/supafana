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

output containerRegistryLoginServer string = cr.properties.loginServer
