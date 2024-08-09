@export()
var groups = {
  SupafanaTestAdmins: 'daa72251-a2ec-4f70-88d6-0e6979a9782a'
  SupafanaProdAdmins: 'e43808b8-a5b1-4ad1-902c-892c1722ac66'
  SupafanaDevAdmins:  'b1c8d785-8d6c-459a-b5ea-8f3bc5bf2af8'
}

// full list in https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-administrator
@export()
var roles = {
  'Key Vault Reader': '21090545-7ca7-4776-b22c-e363652d74d2'
  'Key Vault Crypto User': '12338af0-0e69-4776-bea7-57ae8d297424'
  'Key Vault Administrator': '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  'Owner': '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
}
