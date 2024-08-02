{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/supafana
  ];

  networking.domain = "mkdev.supafana-test.com";
  supafana.localDomain = "supafana-mkdev.local";
  supafana.env = "mkdev";

  sops.secrets."supafana.env" = {
    sopsFile = ../../infra/secrets/supafana-mkdev.env;
    format = "dotenv";
  };
}
