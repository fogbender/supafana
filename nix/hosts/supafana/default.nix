{ config, lib, pkgs, ... }:

let
  keys = import ../../keys;
in
{
  imports = [
    ../../azure-image/common.nix
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
    mk = {
        isNormalUser = true;
        home = "/home/mk";
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [ keys.mk ];
    };
    abs = {
      isNormalUser = true;
      home = "/home/abs";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ keys.abs keys.abs2 ];
    };
  };

}
