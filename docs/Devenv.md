# Developer environment

## Initialization

Choose new env name, normally developer initials with 'dev' suffix: `newdev`.

### Create env resource group and registered application

```bash
scripts/azure-dev-env.sh -n newdev
```
It will output lines that you need to add to your `local.env` file:

```bash
...
Env:            newdev
Resource group: supafana-newdev-rg
Domain:         newdev.supafana-test.com
Local domain:   supafana-newdev.local
App name:       supafana-newdev-app

Add to your local.env:
export SUPAFANA_AZURE_CLIENT_ID="XXXXXXX-5c0c-4c4e-8c9b-2da39ec0f12c"
export SUPAFANA_AZURE_CLIENT_SECRET="XXXXXXX_vrMYYxQ8_zqGl.Ybzyjs3chyWNia1i"
export SUPAFANA_DOMAIN="newdev.supafana-test.com"
export SUPAFANA_ENV="newdev"
export SUPAFANA_AZURE_RESOURCE_GROUP="supafana-newdev-rg"
```

### Create Azure infrastructure in new resource group:

Copy one of `infra/resources/supafana-xxdev.bicepparam` files to new `infra/resources/supafana-newdev.bicepparam` and replace env name in it.

Run azure deployment with new bicepparam file:

```bash
 az deployment group create -c --debug --name supafana-newdev-init-deploy --resource-group supafana-newdev-rg --parameters infra/resources/supafana-newdev.bicepparam
```

### Create secrets file

Find new key vault sops key:

```bash
az keyvault key show --name sops-key --vault-name supafana-newdev-vault  --query 'key.kid' -o tsv
> https://supafana-newdev-vault.vault.azure.net/keys/sops-key/ca3be5c0b9c14439a2b149037133b193
```

Add new entry to the `.sops.yaml` file:

```yaml
creation_rules:
 ...
 - path_regex: -newdev\.env$
    azure_keyvault: https://supafana-newdev-vault.vault.azure.net/keys/sops-key/ca3be5c0b9c14439a2b149037133b193
```

Copy one of the secrets file to the new one:

```bash
sops -d infra/secrets/supafana-kndev.env > infra/secrets/supafana-newdev.env
```

Edit it and encrypt:

```bash
sops -e -i infra/secrets/supafana-newdev.env
```

### Create nixOS deployment configuration

Copy one of `nix/hosts/supafana-xxxdev.nix` files to new `nix/hosts/supafana-newdev.nix`
Update it.

Add nixos configuration and deploy entries to flake.nix with new `supafana-newdev` host.

Deploy:

```bash
deploy .#supafana-newdev
```


## Running project

Open new nix shell: `nix develop` and run next commands:

- `make`: will start dev server and database
- `make web-start`: starts UI
- `make proxy-start`: starts local proxy

on `localhost:3901` you should see proxied site with local UI and local server and database, but with remote grafana instances from Azure.


