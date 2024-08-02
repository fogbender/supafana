{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.supafana;
in
{
  imports = [
    ../supafana-base
    ./nginx.nix
    ./supafana-options.nix
    ./decrypt-sops-service.nix
    inputs.sops-nix.nixosModules.sops
    ./supafana-service.nix
  ];

  networking.search = [ cfg.localDomain ];

  environment.systemPackages = with pkgs; [
    git
    htop
    azure-cli
    jq
  ];

  services.supafana = {
    enable = true;
    environmentFiles = [ cfg.secretsFile ];
    environment = cfg.environment;
  };
}
