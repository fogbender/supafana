param env string
param subnetId string
param location string = resourceGroup().location

@allowed([ 'Free', 'Standard' ])
param sku string = 'Standard'
param name string = 'supafana-${env}-web'

var privateEndpointName = '${name}-endpoint'

resource web 'Microsoft.Web/staticSites@2022-09-01' = {
    name: name

  //Error using default eastus region:
  //  The provided location 'eastus' is not available for resource type 'Microsoft.Web/staticSites'.
  //  List of available regions for the resource type is 'westus2,centralus,eastus2,westeurope,eastasia'.
    location: 'eastus2'

    properties: {
        publicNetworkAccess: 'Enabled'
    }
    sku: {
        name: sku
    }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: web.id
          groupIds: [
            'staticSites'
          ]
        }
      }
    ]
  }
}
