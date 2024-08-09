param env string
param adminGroupName string

param keyVaultName string = 'supafana-${env}-vault'
param sopsKeyName string = 'sops-key'
param location string = resourceGroup().location

import { groups } from './constants.bicep'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
  }
}

module ownerRoleAssignment './role-assignment.bicep' = {
  name: 'owner-role-assignment'
  dependsOn: [ keyVault ]
  params: {
    keyVaultName: keyVaultName
    roleName: 'Owner'
    principalId: groups[adminGroupName]
    principalType: 'Group'
  }
}

module userRoleAssignment './role-assignment.bicep' = {
  name: 'user-role-assignment'
  dependsOn: [ keyVault ]
  params: {
    keyVaultName: keyVaultName
    roleName: 'Key Vault Crypto User'
    principalId: groups[adminGroupName]
    principalType: 'Group'
  }
}


resource sopsKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  name: sopsKeyName
  parent: keyVault
  dependsOn: [
    keyVault
    ownerRoleAssignment
  ]
  properties: {
    kty: 'RSA'
    keySize: 2048
    keyOps: [
      'decrypt'
      'encrypt'
    ]
  }
}

output keyVaultName string = keyVaultName
output keyVaultId string = keyVault.id
output sopsKeyId string = sopsKey.id
