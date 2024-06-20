{ config, lib, pkgs, ... }:

{
  security.acme.defaults.email = "admin@supafana.com";
  security.acme.acceptTerms = true;

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  services.nginx.virtualHosts."supafana.com" = {
    forceSSL = true;
    enableACME = true;
    listen = [
      {port=443; addr="0.0.0.0"; ssl=true;}
      {port=80; addr="0.0.0.0"; ssl=false;}
    ];
    locations = {
      "/" = {
        root = ./site;
      };
    };
  };
}
