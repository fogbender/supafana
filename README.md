# Supafana | https://supafana.com
## Metrics and observability SaaS for [Supabase](https://supabase.com) based on [supabase-grafana](https://github.com/supabase/supabase-grafana)

### Building and pushing supabase-grafana Docker image

``` bash
az login
az acr login supafanacr
docker build supabase-grafana --tag supabase-grafana
docker tag supabase-grafana supafanacr.azurecr.io/supabase-grafana:<VERSION>
docker push supafanacr.azurecr.io/supabase-grafana:<VERSION> 
```

- Update VM grafana image with new <VERSION> in file `nix/hosts/grafana/grafana-container.nix`. 
- Upload new VM grafana image version (see next section).

### NixOS Azure image creation/upload

To test Azure image build:

> nix build '.#supafana-image'

it should create `result` directory with VHD image inside.

To create and upload Azure image:

``` bash
az login

# uploading supafana image
scripts/upload-image-gallery.sh \
  -g supafana-common-rg \
  -r supafanasig \
  -n supafana \
  -v '0.0.1' \
  -l eastus \
  -i '.#supafana-image'
  
# uploading grafana image
scripts/upload-image-gallery.sh \
  -g supafana-common-rg \
  -r supafanasig \
  -n grafana \
  -v '0.0.1' \
  -l eastus \
  -i '.#grafana-image'
```

### Grafana instance provisioning

Run `./infra/hosts/grafana.bicep` template provide parameters:

  - supabaseProjectRef - supabase project referece id
  - supabaseServiceRoleKey - service role key
  - supafanaDomain - supafana domain (supafana-test.com for test, supafana.com for prod)
  - grafanaPassword - optional admin user's password (default password is admin)

Use `supafana-test-rg` resource group for test env deployment.

See examples in `./infra/hosts/grafana-mk-{1,2}.bicepparam

``` bash
az deployment group create -c --debug --name supafana-test-grafana-mk-1-deploy --resource-group supafana-test-rg --parameters infra/hosts/grafana-mk-1.bicepparam
```

After provisioning host should be accessible as `https://<supafanaDomain>/dashboard/<supabaseProjectRef>`:

Example: `https://supafana-test.com/dashboard/kczjrdfrkmmofxkbjxex/`

Internally new instance accessible as `<supabaseProjectRef>.supafana.local`:

Example: `kczjrdfrkmmofxkbjxex.supafana.local`

#### SSH access to grafana instance

Grafana instances don't have public IPs, accessible via our main servers (supafana-test.com and supafana.com).
To simplify access add next lines to your `~/.ssh/config` file:

```
Host *.supafana.local
  ProxyJump admin@supafana-test.com
```

With this grafana instances are accessible  directly:

Example: `ssh admin@kczjrdfrkmmofxkbjxex.supafana.local`

#### Grafana instance internals

Internally grafana instance is NixOS VM running supafana-grafana container as `podman-grafana` systemd service.

To examine service use systemd commands:

- `systmectl status podman-grafana`
- `journalctl -u podman-grafana`

To get into grafana container run `podman exec`:

- `sudo podman exec -ti grafana bash`

More info about running container:

- `sudo podman ps`
- `sudo podman inspect grafana`


#### Deleteng Grafana instance and resources

All resources created with grafana instance has tag `vm:<supabaseProjectRef>`. So to delete them you need to filter all resources by tag first:

``` bash
az resource list --tag vm=<supabaseProjectRef> --query "[].id" -o tsv
```

Example:

``` bash
az resource list --tag vm='kczjrdfrkmmofxkbjxex' --query "[].id" -o tsv | xargs -I {} az resource delete --ids {}
```



### Generate Supabase API types

> cd storefront && npx openapi-typescript https://api.supabase.com/api/v1-json -o src/types/supabase-api-schema.d.ts
