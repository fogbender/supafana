param location string = resourceGroup().location
param sharedImageGalleryName string = 'supafanasig'
param sigRoleName string = 'supafana-sig-access'

param containerRegistryName string = 'supafanacr'
param containerRegistrySku string = 'Basic'

param grafanaTemplateSpecName string = 'grafana-template'

// Shared image gallery
resource sig 'Microsoft.Compute/galleries@2023-07-03' = {
  name: sharedImageGalleryName
  location: location
  properties: {
    description: 'Private shared images for Supafana VMs'
  }
}

// Image gallery access role
resource sigRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' = {
  name: guid(subscription().id, sigRoleName)
  properties: {
    roleName: sigRoleName
    description: 'Access to shared gallery images'
    type: 'CustomRole'
    permissions: [
      {
        actions: [
          'Microsoft.Compute/galleries/read'
          'Microsoft.Compute/galleries/images/read'
          'Microsoft.Compute/galleries/images/versions/read'
          'Microsoft.Compute/images/read'
        ]
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
    assignableScopes: [
      subscription().id
      resourceGroup().id
    ]
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

// Grafana VM template spec
resource grafanaTemplateSpec 'Microsoft.Resources/templateSpecs@2022-02-01' = {
  name: grafanaTemplateSpecName
  location: location
  properties: {
    description: 'Grafana template spec'
    displayName: 'Grafana template'
  }
}

output containerRegistryLoginServer string = cr.properties.loginServer
output prodNameServers array = prodDnsZone.properties.nameServers
output testNameServers array = testDnsZone.properties.nameServers
output grafanaTemplateSpecId string = grafanaTemplateSpec.id
