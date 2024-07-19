param keyVaultName string = concat(resourceGroup().name, '-vault')
param sopsKeyName string = 'sops-key'
param location string = resourceGroup().location

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

resource sopsKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  name: sopsKeyName
  parent: keyVault
  properties: {
    kty: 'RSA'
    keyOps: [
      'decrypt'
      'encrypt'
    ]
  }
}

output keyVaultId string = keyVault.id
output sopsKeyId string = sopsKey.id
