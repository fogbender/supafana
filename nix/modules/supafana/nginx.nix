{ config, lib, pkgs, ... }:

let
  urlPrefix = "dashboard";
  domain = config.networking.domain;
  localDomain = config.supafana.localDomain;
in
{
  security.acme.defaults.email = "admin@${domain}";
  security.acme.acceptTerms = true;

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    resolver.addresses = [ "127.0.0.53" ];
  };

  services.nginx.virtualHosts."${domain}" = {
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
      "~ ^/${urlPrefix}/([a-zA-Z0-9]+)(/.*)" = {
        proxyWebsockets = true;
        proxyPass = "http://$1.${config.supafana.localDomain}:8080/${urlPrefix}/$1$2";
      };
    };
  };
}
