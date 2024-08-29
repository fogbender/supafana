# ![Supfana logo](https://supafana.com/_astro/logo.49zwZwxg_1adPvH.svg)
# Supafana
## https://supafana.com
## Metrics and observability SaaS for [Supabase](https://supabase.com), based on [supabase-grafana](https://github.com/supabase/supabase-grafana)
![image](https://github.com/user-attachments/assets/b1441d23-2147-41e9-a887-cacbd99cbcb0)


### Building and pushing supabase-grafana Docker image

``` bash
az login
az acr login supafanacr
docker build supabase-grafana --tag supabase-grafana
docker tag supabase-grafana supafanacr.azurecr.io/supabase-grafana:<VERSION>
docker push supafanacr.azurecr.io/supabase-grafana:<VERSION> 
```

- Update VM grafana image with new <VERSION> in `nix/hosts/grafana/grafana-container.nix`. 
- Upload new VM grafana image version (see next section).

### NixOS Azure image creation/upload

To test Azure image build:

> nix build '.#supafana-image'

This should create a `result` directory containing a VHD image.

To create and upload an image to Azure:

``` bash
az login

# Upload supafana image
scripts/upload-image-gallery.sh \
  -g supafana-common-rg \
  -r supafanasig \
  -n supafana \
  -v '0.0.1' \
  -l eastus \
  -i '.#supafana-image'
  
# Upload grafana image
scripts/upload-image-gallery.sh \
  -g supafana-common-rg \
  -r supafanasig \
  -n grafana \
  -v '0.0.1' \
  -l eastus \
  -i '.#grafana-image'
```

### Grafana instance provisioning

Run the `./infra/hosts/grafana.bicep` template with the following parameters:

  - supabaseProjectRef - supabase project reference id
  - supabaseServiceRoleKey - service role key
  - supafanaDomain - Supafana domain (supafana-test.com for test, supafana.com for prod)
  - grafanaPassword - optional: admin user password (default password is `admin`)

Use `supafana-test-rg` resource group for test env deployment.

See examples in `./infra/hosts/grafana-mk-{1,2}.bicepparam

``` bash
az deployment group create -c --debug --name supafana-test-grafana-mk-1-deploy --resource-group supafana-test-rg --parameters infra/hosts/grafana-mk-1.bicepparam
```

After provisioning, the host should be accessible via `https://<supafanaDomain>/dashboard/<supabaseProjectRef>`:

Example: `https://supafana-test.com/dashboard/kczjrdfrkmmofxkbjxex/`

Internally, the new instance is accessible via `<supabaseProjectRef>.supafana.local`:

Example: `kczjrdfrkmmofxkbjxex.supafana.local`

#### SSH access to Grafana instances

Grafana instances don't have public IPs and can be accessed only via our main servers (supafana-test.com and supafana.com).

To simplify access (to supafana-test.com), add the following lines to your `~/.ssh/config` file:

```
Host *.supafana.local
  ProxyJump admin@supafana-test.com
```

With this, Grafana instances can be accessed directly, e.g., `ssh admin@kczjrdfrkmmofxkbjxex.supafana.local`

#### Grafana instance internals

Internally, each Grafana instance runs on a NixOS VM, which, in turn, runs the `supafana-grafana` container as a `podman-grafana` systemd service.

To examine the service, use systemd commands:

- `systemctl status podman-grafana`
- `journalctl -u podman-grafana`

To get into a Grafana container, run `podman exec`:

- `sudo podman exec -ti grafana bash`

More info about working with containers:

- `sudo podman ps`
- `sudo podman inspect grafana`


#### Deleting Grafana instances and resources

All resources created for a particular Grafana instance are tagged with `vm:<supabaseProjectRef>`. To delete them, filter all resources by tag:

``` bash
az resource list --tag vm=<supabaseProjectRef> --query "[].id" -o tsv
```

Then, delete:

``` bash
az resource list --tag vm='kczjrdfrkmmofxkbjxex' --query "[].id" -o tsv | xargs -I {} az resource delete --ids {}
```



### Generate Supabase API types

> cd storefront && npx openapi-typescript https://api.supabase.com/api/v1-json -o src/types/supabase-api-schema.d.ts
