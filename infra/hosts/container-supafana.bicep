param project string = 'project1'

@description('Container image registry')
param acrName string

@description('Container image resource group')
param acrResourceGroupName string

@description('Location for all resources.')
param location string = resourceGroup().location

param storageAccountName string = '${project}sta'
param containerName string = project
param image string
param cpu int = 1
param memoryInGB int = 2
param grafanaFileShareName string = '${project}-grafana-fs'
param prometheusFileShareName string = '${project}-prometheus-fs'
param supabaseProjectRef string
param supabaseServiceRoleKey string
param grafanaUrl string = 'https://supafana.com'
@secure()
param grafanaPassword string
param vnetName string = 'vNet'
param containerSubnetName string = 'ContainerSubnet'
param privateDnsZoneName string = 'supafana.local'


resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: acrName
  scope: resourceGroup(acrResourceGroupName)
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  name: 'default'
  parent: storageAccount
}

resource grafanaFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  name: grafanaFileShareName
  parent: fileService
  properties: {
    shareQuota: 5120
  }
}

resource prometheusFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  name: prometheusFileShareName
  parent: fileService
  properties: {
    shareQuota: 5120
  }
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          image: image
          resources: {
            requests: {
              cpu: cpu
              memoryInGB: memoryInGB
            }
          }
          volumeMounts: [
            {
              name: 'grafanavolume'
              mountPath: '/data/grafana/data'
            }
            {
              name: 'prometheusvolume'
              mountPath: '/data/prometheus'
            }
          ]
          ports: [
            {
              port: 8080
            }
            {
              port: 80
            }
            {
              port: 443
            }
          ]
          environmentVariables: [
            {
              name: 'SUPABASE_PROJECT_REF'
              value: supabaseProjectRef
            }
            {
              name: 'SUPABASE_SERVICE_ROLE_KEY'
              value: supabaseServiceRoleKey
            }
            {
              name: 'GRAFANA_URL'
              value: grafanaUrl
            }
            {
              name: 'GRAFANA_PASSWORD'
              value: grafanaPassword
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Private'
      ports: [
        {
          protocol: 'tcp'
          port: 80
        }
        {
          protocol: 'tcp'
          port: 443
        }
      ]
    }
    subnetIds: [
      {
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, containerSubnetName)
      }
    ]
    volumes: [
      {
        name: 'grafanavolume'
        azureFile: {
          shareName: grafanaFileShareName
          storageAccountName: storageAccountName
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
      {
        name: 'prometheusvolume'
        azureFile: {
          shareName: prometheusFileShareName
          storageAccountName: storageAccountName
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
    ]
    imageRegistryCredentials: [
      {
        server: '${acrName}.azurecr.io'
        username: acr.listCredentials().username
        password: acr.listCredentials().passwords[0].value
      }
    ]
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, 'StorageBlobDataContributor', uniqueString(containerGroup.id))
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: containerGroup.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource dnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${project}.${privateDnsZoneName}'
  parent: privateDnsZone
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: containerGroup.properties.ipAddress.ip
      }
    ]
  }
}

output containerGroupIP string = containerGroup.properties.ipAddress.ip
output containerGroupDomain string = dnsRecord.name
