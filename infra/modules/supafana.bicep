param location string = resourceGroup().location
param env string
param adminGroupName string

// api specific params
param publicDomain string
param apiImageVersion string = '0.0.2'
param apiVmSize string = 'Standard_B2s'
param apiOsDiskType string = 'Standard_LRS'
param apiOsDiskSizeGB int = 20

// db specific params
param dbVersion string = '15'
param dbSkuName string = 'Standard_B1ms'
param dbSkuTier string = 'Burstable'
param dbDiskSizeGb int = 32

module network './supafana-network.bicep' = {
  name: 'network-module'
  params: {
    location: location
    env: env
  }
}

module secrets './supafana-secrets.bicep' = {
  name: 'secrets-module'
  params: {
    location: location
    env: env
    adminGroupName: adminGroupName
  }
}

module db './supafana-db.bicep' = {
  name: 'db-module'
  dependsOn: [ network ]
  params: {
    location: location
    env: env
    adminGroupName: adminGroupName

    vnetId: network.outputs.vnetId
    apiSubnetId: network.outputs.apiSubnetId
    dbSubnetId: network.outputs.dbSubnetId
  }
}

module api './supafana-api.bicep' = {
  name: 'api-module'
  dependsOn: [
    network
    secrets
    db
  ]
  params: {
    location: location
    env: env
    publicDomain: publicDomain

    vnetId: network.outputs.vnetId
    apiSubnetId: network.outputs.apiSubnetId
    keyVaultName: secrets.outputs.keyVaultName
    imageVersion: apiImageVersion
    vmSize: apiVmSize
    osDiskType: apiOsDiskType
    osDiskSizeGB: apiOsDiskSizeGB
    dbHostName: db.outputs.dbHostName
  }
}

module web './supafana-web.bicep' = {
  name: 'web-module'
  params: {
    location: location
    env: env
    subnetId: network.outputs.apiSubnetId
  }
}
