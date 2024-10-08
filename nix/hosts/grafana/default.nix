{ config, lib, pkgs, ... }:

let
  keys = import ../../keys;
in
{
  imports = [
    ../../modules/azure-image/common.nix
    ./grafana-container.nix
  ];

  services.openssh.settings.PasswordAuthentication = false;
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "@wheel" ];
  networking.search = [ "supafana.local" ];

  users.users = {
    supafana = {
        isNormalUser = true;
        home = "/home/supafana";
        description = "Supafana user";
        extraGroups = [ "podman" ];
        openssh.authorizedKeys.keys = [ keys.abs keys.abs2 keys.mk ];
    };
    admin = {
        isNormalUser = true;
        home = "/home/admin";
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [ keys.mk keys.abs keys.abs2 ];
    };
  };
}
