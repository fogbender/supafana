param dbName string
param principalName string
param principalId string

@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string

resource dbAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2022-12-01' = {
  name: '${dbName}/${principalId}'
  properties: {
    tenantId: subscription().tenantId
    principalType: principalType
    principalName: principalName
  }
}
