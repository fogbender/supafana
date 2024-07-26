import {groups} from 'groups.bicep'

param location string = resourceGroup().location
param virtualNetworkName string = 'vNet'
param supafanaSubnetName string = 'SupafanaSubnet'

param dbName string = 'supafana-test-db'
param dbVersion string = '15'
param dbSkuName string = 'Standard_B1ms'

param dbAdminGroupName string = 'supafana_test_db_admin'
param dbDatabaseName string = 'supafana_test'

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

resource dbAdminGroup 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2022-12-01' = {
  name: concat(dbName, '/', groups[dbAdminGroupName].objectId)
  dependsOn: [
    server
  ]
  properties: {
    tenantId: subscription().tenantId
    principalType: 'Group'
    principalName: dbAdminGroupName
  }
}

resource dbDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-12-01-preview' = {
  name: dbDatabaseName
  parent: server
}

output dbHost string = dbHost
