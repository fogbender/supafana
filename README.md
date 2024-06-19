# supafana


# Azure image creation/upload

To test creation of Azure image:

> nix build '.#supafana-image'

it should create `result` directory with VHD image inside.

To create and upload Azure image:

> az login
> scripts/upload-image.sh -g MkImageResourceGroup -n supafana -l eastus -i '.#supafana-image'

