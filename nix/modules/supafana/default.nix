{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.supafana;
in
{
  imports = [
    ../supafana-base
    ./nginx.nix
    ./supafana-options.nix
    ./decrypt-sops-service.nix
    inputs.sops-nix.nixosModules.sops
    ./supafana-service.nix
  ];

  networking.search = [ cfg.localDomain ];

  environment.systemPackages = with pkgs; [
    git
    htop
    azure-cli
    jq
  ];

  services.supafana = {
    enable = true;
    environmentFiles = [ cfg.secretsFile ];
    environment = {
      PG_HOST = "supafana-${cfg.env}-db.postgres.database.azure.com";
      PG_USER = "supafana-${cfg.env}-api";
      PG_DB = "supafana_${cfg.env}";
      PG_PASS = "AZURE_IDENTITY";
      PG_SSL_ENABLE = "true";
      SUPAFANA_AZURE_CLIENT_ID = "AZURE_IDENTITY";
      SUPAFANA_AZURE_RESOURCE_GROUP = "supafana-${cfg.env}-rg";
      SUPAFANA_API_URL = "https://${config.networking.domain}";
      SUPAFANA_STOREFRONT_URL = "https://${config.networking.domain}";
      SUPAFANA_DOMAIN = config.networking.domain;
      SUPAFANA_ENV = cfg.env;
    } // cfg.environment;
  };
}
