#!/usr/bin/env sh


usage() {
  echo ''
  echo 'USAGE: '
  echo ''
  echo '-a --acr-name       Azure container registry name'
  echo '                    default: supafanacr'
  echo ''
  echo '-n --name           Service principal name'
  echo '                    default: supafanacr_reader'
  echo ''
  echo '-r --role           ACR prinicpal role. Values:'
  echo '                    acrpull:     pull only (default)'
  echo '                    acrpush:     push and pull'
  echo '                    owner:       push, pull, and assign roles '
}


# Options
while [ $# -gt 0 ]; do
  case "$1" in
    -a|--acr-name)
      acr_name="$2"
      ;;
    -n|--name)
      principal_name="$2"
      ;;
    -r|--role)
      role="$2"
      ;;
    -h|--help)
      usage
      exit 1
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument *\n"
      printf "***************************\n"
      usage
      exit 1
  esac
  shift
  shift
done

# Defaults
acr_name="${acr_name:-"supafanacr"}"
principal_name="${principal_name:-"supafanacr_reader"}"
role="${role:-"acrpull"}"

# Obtain the full registry ID
ACR_REGISTRY_ID=$(az acr show --name $acr_name --query "id" --output tsv)
# echo $registryId

PASSWORD=$(az ad sp create-for-rbac --name $principal_name --scopes $ACR_REGISTRY_ID --role $role --query "password" --output tsv)
USER_NAME=$(az ad sp list --display-name $principal_name --query "[].appId" --output tsv)

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
echo "Service principal ID: $USER_NAME"
echo "Service principal password: $PASSWORD"
