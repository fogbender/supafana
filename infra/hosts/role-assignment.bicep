param principalId string
param keyVaultName string
param roleName string

// full list in https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-administrator
var roles = {
  'Key Vault Reader': '21090545-7ca7-4776-b22c-e363652d74d2'
  'Key Vault Crypto User': '12338af0-0e69-4776-bea7-57ae8d297424'
}

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: roles[roleName]
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

var roleAssignmentName = guid(keyVault.id, principalId, roleDefinition.id)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  scope: keyVault
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: principalId
  }
}
