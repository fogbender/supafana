{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/supafana
  ];

  networking.domain = "supafana.com";
  supafana.azureWebDomain = "proud-pebble-06806600f.5.azurestaticapps.net";
  supafana.env = "prod";

  supafana.environment = {
    SUPAFANA_TRIAL_LENGTH_MIN = "30";
  };
}
