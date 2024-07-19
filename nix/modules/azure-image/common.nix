{ pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/virtualisation/azure-common.nix"
  ];

  system.stateVersion = "24.05";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.growPartition = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  virtualisation.azure.agent.enable = true;
  services.cloud-init.enable = true;
  systemd.services.cloud-config.serviceConfig = {
    Restart = "on-failure";
  };
  services.cloud-init.network.enable = true;
  networking.useDHCP = true;
  networking.useNetworkd = true;
  networking.nameservers = [ "168.63.129.16" ];

  nix.settings = {
    warn-dirty = false;
    experimental-features = [ "nix-command" "flakes" ];
  };
}
