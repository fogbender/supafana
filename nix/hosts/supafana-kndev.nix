{ config, lib, pkgs, ... }:
{
  imports = [
    ../modules/supafana
  ];

  networking.domain = "kndev.supafana-test.com";
  supafana.azureWebDomain = "white-river-0b00acd0f.5.azurestaticapps.net";
  supafana.env = "kndev";

  supafana.environment = {
    SUPAFANA_TRIAL_LENGTH_MIN = "30";
  };
}
