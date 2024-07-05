# supafana


# Azure image creation/upload

To test creation of Azure image:

> nix build '.#supafana-image'

it should create `result` directory with VHD image inside.

To create and upload Azure image:

``` bash
az login

# uploading supafana image
scripts/upload-image-gallery.sh \
  -g supafana-images-rg \
  -r supafanasig \
  -n supafana \
  -v '0.0.1' \
  -l eastus \
  -i '.#supafana-image'
  
# uploading grafana image
scripts/upload-image-gallery.sh \
  -g supafana-images-rg \
  -r supafanasig \
  -n grafana \
  -v '0.0.1' \
  -l eastus \
  -i '.#grafana-image'
```
## Generate Supabase API types

> cd storefront && npx openapi-typescript https://api.supabase.com/api/v1-json -o src/types/supabase-api-schema.d.ts
