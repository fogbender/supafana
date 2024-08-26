{ config, lib, pkgs, ... }:

with lib;
{
  options.supafana = {
    azureWebDomain = mkOption {
      description = "Azure static site domain";
      example = literalExample "purple-hill-096a9150f.5.azurestaticapps.net";
      type = types.str;
    };

    env = mkOption {
      description = "Supafana env name";
      example = "test";
      type = types.str;
    };

    localDomain = mkOption {
      description = "Local domain for resolving grafana hosts";
      default = "supafana-${config.supafana.env}.local";
      type = types.str;
    };

    environment = mkOption {
      type = with types; attrsOf str;
      description = mdDoc "Additional environment variables";
      default = {};
    };

    secretsFile = mkOption {
      type = types.path;
      description = "Path to local encrypted file with environment secrets";
      default = ../../../infra/secrets/supafana-${config.supafana.env}.env;
      example = literalExample "secrets/test.env";
    };
  };
}
