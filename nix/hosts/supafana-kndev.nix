{ config, lib, pkgs, ... }:

let
  env = "kndev";
  domain = "kndev.supafana-test.com";
  azureWebDomain = "white-river-0b00acd0f.5.azurestaticapps.net";
in
{
  imports = [
    ../modules/supafana
  ];

  networking.domain = domain;
  supafana.localDomain = "supafana-${env}.local";
  supafana.azureWebDomain = azureWebDomain;
  supafana.env = env;
  supafana.secretsFile = config.sops.secrets."supafana.env".path;

  supafana.environment = {
    PG_HOST = "supafana-${env}-db.private.postgres.database.azure.com";
    PG_USER = "supafana-${env}-api";
    PG_DATABASE = "supafana_${env}";
    PG_PASS = "AZURE_IDENTITY";
    SUPAFANA_API_URL = "${domain}/api";
    SUPAFANA_STOREFRONT_URL = domain;
    SUPAFANA_AZURE_RESOURCE_GROUP = "supafana-${env}-rg";
  };

  sops.secrets."supafana.env" = {
    sopsFile = ../../infra/secrets/supafana-${env}.env;
    format = "dotenv";
  };
}
