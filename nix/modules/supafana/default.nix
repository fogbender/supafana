{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../supafana-base
    ./nginx.nix
    ./supafana-options.nix
    ../decrypt-sops-service.nix
    inputs.sops-nix.nixosModules.sops
  ];

  networking.search = [ config.supafana.localDomain ];

  environment.systemPackages = with pkgs; [
    git
    htop
    azure-cli
  ];
}
