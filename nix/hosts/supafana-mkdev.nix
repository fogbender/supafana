{ config, lib, pkgs, ... }:

let
  env = "mkdev";
  domain = "mkdev.supafana-test.com";
  azureWebDomain = "purple-hill-096a9150f.5.azurestaticapps.net";
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
    PG_HOST = "supafana-${env}-db.postgres.database.azure.com";
    PG_USER = "supafana-${env}-api";
    PG_DB = "supafana_${env}";
    PG_PASS = "AZURE_IDENTITY";
    PG_SSL_ENABLE = "true";
    SUPAFANA_AZURE_CLIENT_ID = "AZURE_IDENTITY";
    SUPAFANA_API_URL = "https://${domain}";
    SUPAFANA_STOREFRONT_URL = domain;
    SUPAFANA_AZURE_RESOURCE_GROUP = "supafana-${env}-rg";
    SUPAFANA_TRIAL_LENGTH_MIN = "30";
  };

  sops.secrets."supafana.env" = {
    sopsFile = ../../infra/secrets/supafana-${env}.env;
    format = "dotenv";
  };
}
