param location string = resourceGroup().location
param virtualNetworkName string = 'vNet'
param supafanaSubnetName string = 'SupafanaSubnet'

param dbName string = 'supafana-db'
param dbVersion string = '15'
param dbSkuName string = 'Standard_B1ms'

param dbAdminName string = 'postgres'

@secure()
param dbAdminPassword string = 'init'

param dbAdminGroupName string = 'SupafanaTestDbAdmins'

@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param dbSkuTier string = 'Burstable'
param dbDiskSizeGb int = 32

module network './network.bicep' = {
  name: 'supafana-network'
}

var dbHost = '${dbName}.private.postgres.database.azure.com'

// Private DNS Zone
resource privateDbDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dbHost
  location: 'global'
  resource vNetLink 'virtualNetworkLinks' = {
    name: '${dbName}-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: { id: network.outputs.vNetId }
    }
  }
}

resource server 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: dbName
  location: location
  sku: {
    name: dbSkuName
    tier: dbSkuTier
  }
  properties: {
    administratorLogin: dbAdminName
    administratorLoginPassword: dbAdminPassword
    version: dbVersion
    storage: {
      storageSizeGB: dbDiskSizeGb
    }
    network: {
      delegatedSubnetResourceId: network.outputs.dbSubnetId
      privateDnsZoneArmResourceId: privateDbDnsZone.id
      publicNetworkAccess: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId: subscription().tenantId
    }
  }
}

resource dbAdminGroup 'Microsoft.Graph/groups@1.0' existing = {
  displayName: dbAdminGroupName
}



output dbHost string = dbHost
