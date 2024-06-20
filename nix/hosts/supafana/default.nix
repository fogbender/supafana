{ config, lib, pkgs, ... }:

let
  keys = import ../../keys;
in
{
  imports = [
    ../../azure-image/common.nix
    ./nginx.nix
  ];

  services.openssh.settings.PasswordAuthentication = false;
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "@wheel" ];

  users.users = {
    supafana = {
        isNormalUser = true;
        home = "/home/supafana";
        description = "Supafana user";
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
