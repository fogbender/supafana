{ config, lib, pkgs, ... }:

{
  options.supafana.localDomain = lib.mkOption {
    description = "Local domain for resolving grafana hosts";
    default = "supafana.local";
    type = lib.types.str;
  };

  options.supafana.env = lib.mkOption {
    description = "Supafana env name";
    default = "test";
    type = lib.types.str;
  };
}
