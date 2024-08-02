{ config, lib, pkgs, ... }:

{
  systemd.services.decrypt-sops = {
    description = "Decrypt sops secrets";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # in network is not ready
      Restart = "on-failure";
      RestartSec = "2s";
    };
    # TODO implement proper sops-nix invocation instead of abusing activationScripts
    script = config.system.activationScripts.setupSecrets.text;
   };
}
