#!/usr/bin/env bash

####################################################
# AZ LOGIN CHECK                                   #
####################################################

# Making  sure  that  one   is  logged  in  (to  avoid
# surprises down the line).
if [ $(az account list | jq -r 'length') -eq 0 ]
then
  echo
  echo '********************************************************'
  echo '* Please log  in to  Azure by  typing "az  login", and *'
  echo '* repeat the "./upload-image.sh" command.              *'
  echo '********************************************************'
  exit 1
fi

####################################################
# HELPERS                                          #
####################################################

disk_id() {
  az disk show \
    --resource-group "${resource_group}" \
    --name "${disk_name}"        \
    --query "[id]"              \
    --output tsv
}

image_version_id() {
  az sig image-version show \
    --gallery-image-definition "${image_name}" \
    --gallery-image-version "${image_version}" \
    --gallery-name "${gallery_name}" \
    --resource-group "${resource_group}" \
    --query "[id]" \
    --output tsv
}

image_definition_id() {
  az sig image-definition show \
    --gallery-image-definition "${image_name}" \
    --gallery-name "${gallery_name}" \
    --resource-group "${resource_group}" \
    --query "[id]" \
    --output tsv
}


usage() {
  echo ''
  echo 'USAGE: (Every switch requires an argument)'
  echo ''
  echo '-g --resource-group REQUIRED Created if does  not exist. Will'
  echo '                             house a new disk and the created'
  echo '                             image.'
  echo ''
  echo '-r --gallery-name   REQUIRED Shared image gallery name.'
  echo '                             Created if does not exist.'
  echo '                             Allowed characters are English alphanumeric characters, '
  echo '                             with underscores and periods allowed in the middle, '
  echo '                             up to 80 characters total. All other special characters, '
  echo '                             including dashes, are disallowed.'
  echo ''
  echo '-n --image-name     REQUIRED The  name of  the image  created'
  echo ''
  echo '-v --image-version  REQUIRED The  version of  the image  created'
  echo '                             (disk will have <name>-<version> name).'
  echo ''
  echo '-i --image-nix      Nix  expression   to  build  the'
  echo '                    image. Default value:'
  echo '                    "./examples/basic/image.nix".'
  echo ''
  echo '-l --location       Values from `az account list-locations`.'
  echo '                    Default value: "westus2".'
  echo ''
  echo '-d --debug          Debug'
  echo ''
}

####################################################
# SWITCHES                                         #
####################################################

# https://unix.stackexchange.com/a/204927/85131
while [ $# -gt 0 ]; do
  case "$1" in
    -i|--image-nix)
      image_nix="$2"
      ;;
    -l|--location)
      location="$2"
      ;;
    -g|--resource-group)
      resource_group="$2"
      ;;
    -r|--gallery-name)
      gallery_name="$2"
      ;;
    -n|--image-name)
      image_name="$2"
      ;;
    -v|--image-version)
      image_version="$2"
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

if [ -z "${image_name}" ] || [ -z "${resource_group}" ] || [ -z "${gallery_name}" ] || [ -z "${image_version}" ]
then
  printf "************************************\n"
  printf "* Error: Missing required argument *\n"
  printf "************************************\n"
  usage
  exit 1
fi

####################################################
# DEFAULTS                                         #
####################################################

image_nix_d="${image_nix:-"./examples/basic/image.nix"}"
location_d="${location:-"westus2"}"
disk_name="${image_name}-${image_version}"

####################################################
# PUT IMAGE INTO AZURE CLOUD                       #
####################################################

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

nix build             \
  --out-link "azure"  \
  "${image_nix_d}"

# Make resource group exists
if ! az group show --resource-group "${resource_group}" &>/dev/null
then
  az group create     \
    --name "${resource_group}" \
    --location "${location_d}" \
    "${debug}"
fi

# Make image gallery exists
if ! az sig show --resource-group "${resource_group}" --gallery-name "${gallery_name}" &>/dev/null
then
  az sig create \
    --resource-group "${resource_group}" \
    --gallery-name "${gallery_name}" \
    "${debug}"
fi

# Make image definition exists
if ! image_definition_id &>/dev/null
then
  az sig image-definition create \
    --resource-group "${resource_group}" \
    --gallery-name "${gallery_name}" \
    --gallery-image-definition "${image_name}" \
    --publisher "Supafana" \
    --offer "${image_name}Offer" \
    --sku "${image_name}SKU" \
    --os-type "Linux" \
    --hyper-v-generation "V2" \
    --os-state "Generalized" \
    "${debug}"
fi


# NOTE: The  disk   access  token   song/dance  is
#       tedious  but allows  us  to upload  direct
#       to  a  disk  image thereby  avoid  storage
#       accounts (and naming them) entirely!

if ! disk_id &>/dev/null
then
  img_file="$(readlink -f ./azure/nixos.vhd)"
  bytes="$(stat -c %s ${img_file})"

  az disk create                \
    --resource-group "${resource_group}" \
    --name "${disk_name}" \
    --hyper-v-generation V2 \
    --upload-type Upload \
    --upload-size-bytes "${bytes}" \
    "${debug}"

  timeout=$(( 60 * 60 )) # disk access token timeout
  sasurl="$(\
    az disk grant-access               \
      --access-level Write             \
      --resource-group "${resource_group}"      \
      --name "${disk_name}"             \
      --duration-in-seconds ${timeout} \
      --query "[accessSas]"            \
      --output tsv \
      "${debug}"
  )"

  azcopy copy "${img_file}" "${sasurl}" \
    --blob-type PageBlob

  # https://docs.microsoft.com/en-us/cli/azure/disk?view=azure-cli-latest#az-disk-revoke-access
  # > Revoking the SAS will  change the state of
  # > the managed  disk and allow you  to attach
  # > the disk to a VM.
  az disk revoke-access         \
    --resource-group "${resource_group}" \
    --name "${disk_name}"
fi

if ! image_version_id &>/dev/null
then
  az sig image-version create \
    --resource-group "${resource_group}" \
    --gallery-name "${gallery_name}" \
    --gallery-image-definition "${image_name}" \
    --gallery-image-version "${image_version}" \
    --os-snapshot "$(disk_id)" \
    "${debug}"
fi

echo "Image creation completed!"
echo "shared_gallery_image_id: $(image_version_id)"

# delete the nix build link
rm -fr ./azure
