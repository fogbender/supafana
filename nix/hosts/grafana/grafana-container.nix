{ config, lib, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 8080 80 ];

  virtualisation.oci-containers.containers.grafana = {
    image = "supafanastgcr.azurecr.io/supafana-image:2024.6.3";
    login.registry = "https://supafanastgcr.azurecr.io";
    login.username = "supafanastgcr";
    login.passwordFile = "/var/lib/supafana/registry-pass.txt";
    environmentFiles = [ "/var/lib/supafana/supafana.env" ];
    ports = [ "8080:8080" ];
  };
}

