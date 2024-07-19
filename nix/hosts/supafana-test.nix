{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/supafana
  ];

  networking.domain = "supafana-test.com";

  sops.secrets."supafana.env" = {
    sopsFile = ../../infra/secrets/supafana-test.env;
    format = "dotenv";
  };
}
