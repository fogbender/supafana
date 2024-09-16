{ config, lib, pkgs, ... }:

let
  passFile = ./registry-pass.txt;
in
{
  networking.firewall.allowedTCPPorts = [ 8080 9090];

  virtualisation.oci-containers.containers.grafana = {
    image = "supafanacr.azurecr.io/supabase-grafana:2024.09.06";
    login.registry = "https://supafanacr.azurecr.io";
    # readonly principal
    login.username = "df1f34b8-bc26-4606-b4cc-c1e08511e709";
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
