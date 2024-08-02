module secTest '../modules/supafana-secrets.bicep' = {
  name: 'secrets-test'
  params: {
    env: 'prod'
    adminGroupName: 'SupafanaProdAdmins'
  }
}
