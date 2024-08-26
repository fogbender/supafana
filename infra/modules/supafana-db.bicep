import {groups} from 'constants.bicep'

param location string = resourceGroup().location
param env string
param adminGroupName string

param vnetId string
param apiSubnetId string
param dbSubnetId string

param dbHostName string = 'supafana-${env}-db'
param dbVersion string = '15'
param dbSkuName string = 'Standard_B1ms'
param dbDatabaseName string = 'supafana_${env}'

@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param dbSkuTier string = 'Burstable'
param dbDiskSizeGb int = 32

var dbPrivateDomainName = 'private.postgres.database.azure.com'
var dbDomainName = '${dbHostName}.postgres.database.azure.com'

// Private DNS Zone
resource privateDbDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dbPrivateDomainName
  location: 'global'
  resource vNetLink 'virtualNetworkLinks' = {
    name: '${dbHostName}-vnet-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: { id: vnetId }
    }
  }
}

resource db 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: dbHostName
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
      delegatedSubnetResourceId: dbSubnetId
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
  name: concat(dbHostName, '/', groups[adminGroupName])
  dependsOn: [
    db
  ]
  properties: {
    tenantId: subscription().tenantId
    principalType: 'Group'
    principalName: adminGroupName
  }
}

resource dbDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-12-01-preview' = {
  name: dbDatabaseName
  parent: db
}

output dbDomainName string = dbDomainName
output dbHostName string = dbHostName
output dbDatabaseName string = dbDatabaseName
