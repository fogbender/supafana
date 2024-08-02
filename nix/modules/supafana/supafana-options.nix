{ config, lib, pkgs, ... }:

with lib;
{
  options.supafana = {
    localDomain = mkOption {
      description = "Local domain for resolving grafana hosts";
      default = "supafana.local";
      type = types.str;
    };

    env = mkOption {
      description = "Supafana env name";
      default = "test";
      type = types.str;
    };

    environment = mkOption {
      type = with types; attrsOf str;
      description = mdDoc "Additional environment variables";
      default = {};
    };

    secretsFile = mkOption {
      type = types.path;
      description = "Environment file with secrets";
    };
  };
}
