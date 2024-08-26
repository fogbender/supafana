{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/supafana
  ];

  networking.domain = "mkdev.supafana-test.com";
  supafana.azureWebDomain = "purple-hill-096a9150f.5.azurestaticapps.net";
  supafana.env = "mkdev";
  supafana.environment = {
    SUPAFANA_TRIAL_LENGTH_MIN = "30";
  };
}
