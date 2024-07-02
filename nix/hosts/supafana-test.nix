{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/supafana
  ];

  networking.domain = "supafana-test.com";
}
