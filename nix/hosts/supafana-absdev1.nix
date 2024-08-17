{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/supafana
  ];

  networking.domain = "absdev1.supafana-test.com";
  supafana.azureWebDomain = "icy-ground-03d19110f.5.azurestaticapps.net";
  supafana.env = "absdev1";

  supafana.environment = {
    SUPAFANA_TRIAL_LENGTH_MIN = "30";
  };

  sops.secrets."supafana.env" = {
    sopsFile = ../../infra/secrets/supafana-${config.supafana.env}.env;
    format = "dotenv";
  };
}
