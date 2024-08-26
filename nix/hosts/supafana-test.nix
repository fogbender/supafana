{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/supafana
  ];

  networking.domain = "supafana-test.com";
  supafana.azureWebDomain = "white-tree-0b6500c0f.5.azurestaticapps.net";
  supafana.env = "test";

  supafana.environment = {
    SUPAFANA_TRIAL_LENGTH_MIN = "30";
  };
}
