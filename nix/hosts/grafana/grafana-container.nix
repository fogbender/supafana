{ config, lib, pkgs, ... }:

let
  passFile = ./registry-pass.txt;
in
{
  networking.firewall.allowedTCPPorts = [ 8080 9090];

  virtualisation.oci-containers.containers.grafana = {
    image = "supafanastgcr.azurecr.io/supafana-image:2024.07.08";
    login.registry = "https://supafanastgcr.azurecr.io";
    login.username = "supafanastgcr";
    # TODO move acr password to sops file
    login.passwordFile = "${passFile}";
    environmentFiles = [ "/var/lib/supafana/supafana.env" ];
    ports = [ "8080:8080" "9090:9090" ];
    volumes = [ "/var/lib/supafana/data:/data" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/supafana/data 0770 root root -"
  ];
}
