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
        proxyWebsockets = true;
        proxyPass = "https://${config.supafana.azureWebDomain}";
        recommendedProxySettings = false;
        extraConfig = ''
          proxy_set_header        X-Real-IP $remote_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header        X-Forwarded-Proto $scheme;
          proxy_set_header        X-Forwarded-Host $host;
          proxy_set_header        X-Forwarded-Server $host;
        '';
      };
      "/api" = {
        proxyWebsockets = true;
        proxyPass = "http://localhost:9080";
      };
      "~ ^/${urlPrefix}/([a-zA-Z0-9]+)(/.*)?" = {
        proxyWebsockets = true;
        proxyPass = "http://supafana-${config.supafana.env}-grafana-$1.${config.supafana.localDomain}:8080/${urlPrefix}/$1$2";
      };
    };
  };
}
