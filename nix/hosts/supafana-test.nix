{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/supafana
  ];

  networking.domain = "supafana-test.com";
  supafana.secretsFile = config.sops.secrets."supafana.env".path;

  sops.secrets."supafana.env" = {
    sopsFile = ../../infra/secrets/supafana-test.env;
    format = "dotenv";
  };
}
