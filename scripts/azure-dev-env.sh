#!/usr/bin/env sh


usage() {
  echo ''
  echo 'Creates new resource group, dev app with permissions and secret.'
  echo ''
  echo 'USAGE: '
  echo ''
  echo '-n --name  REQUIRED Dev env name (mkdev)'
  echo ''
  echo '-l --location       Values from `az account list-locations`.'
  echo '                    Default value: "eastus".'
  echo '-h --help           Help'
  echo ''
  echo '-d --debug          Debug'
  echo ''
}


# Options
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--name)
      name="$2"
      ;;
    -l|--location)
      location="$2"
      ;;
    -d|--debug)
      debug="--debug"
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

if [[ -z "${name}" ]]
then
  printf "************************************\n"
  printf "* Error: Missing required argument *\n"
  printf "************************************\n"
  usage
  exit 1
fi

# Defaults

location="${location:-"eastus"}"

set -euxo pipefail

app_name="supafana-${name}-app"
resource_group="supafana-${name}-rg"

# Create the App Registration
app_id=$(az ad app create --display-name "$app_name" --query appId -o tsv ${debug:+"$debug"})

# Create a Service Principal for the App Registration
app_sp_id=$(az ad sp create --id $app_id --query id -o tsv ${debug:+"$debug"})

# Create a client secret for the App Registration
app_secret=$(az ad app credential reset --id $app_id --append --query password -o tsv ${debug:+"$debug"})

# Create resource group if not exists
if ! az group show --resource-group "${resource_group}" &>/dev/null
then
  az group create     \
    --name "${resource_group}" \
    --location "${location}" \
    ${debug:+"$debug"}
fi

# Get the Subscription ID
subscription_id=$(az account show --query id -o tsv)
group_scope="subscriptions/${subscription_id}/resourcegroups/${resource_group}"
sub_scope="subscriptions/${subscription_id}"

# Set roles for the app
az role assignment create --assignee $app_sp_id --role "Virtual Machine Contributor" --scope ${group_scope} ${debug:+"$debug"}
az role assignment create --assignee $app_sp_id --role "Template Spec Reader" --scope ${sub_scope} ${debug:+"$debug"}
az role assignment create --assignee $app_sp_id --role "supafana-sig-access"  --scope ${sub_scope} ${debug:+"$debug"}

# Domains
public_domain="${name}.supafana-test.com"
local_domain="supafana-${name}.local"

# Output the important details
set +x
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Env:            $name"
echo "Resource group: $resource_group"
echo "Domain:         $public_domain"
echo "Local domain:   $local_domain"
echo "App name:       $app_name"
echo ''
echo "Add to your local.env:"
echo "export SUPAFANA_AZURE_CLIENT_ID=\"${app_id}\""
echo "export SUPAFANA_AZURE_CLIENT_SECRET=\"${app_secret}\""
echo "export SUPAFANA_DOMAIN=\"${public_domain}\""
echo "export SUPAFANA_ENV=\"${name}\""
echo "export SUPAFANA_AZURE_RESOURCE_GROUP=\"supafana-${name}-rg\""
