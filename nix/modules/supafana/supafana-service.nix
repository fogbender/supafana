{ config, lib, pkgs, ... }:

with lib;
let
  supafana = pkgs.supafana;
  cfg = config.services.supafana;
  cookieFile = cfg.workDir + "/.cookie";
in
{
  options.services.supafana = {
    enable = lib.mkEnableOption "Supafana service";

    environmentFiles = lib.mkOption {
      description = "List of environment files.";
      type = with lib.types; listOf path;
      default = [];
    };

    environment = lib.mkOption {
      description = "Additional environment vars";
      type = with types; attrsOf str;
      default = {};
    };

    migrateDb = mkOption {
      default = true;
      type = types.bool;
      description = ''
          Set to true if database migration should be performed on start of Supafana service.
        '';
    };

    workDir = mkOption {
      default = "/run/supafana";
      type = types.path;
      description = "The working directory used. If not exists it will be created with 0700 access for user.";
    };

    package = mkOption {
      description = "Supafana package to use";
      default = supafana.server;
      defaultText = "supafana.server";
      type = types.package;
      example = literalExample "supafana.server";
    };

    packages = mkOption {
      default = [ pkgs.bash ];
      defaultText = "[ pkgs.bash ]";
      type = with types; listOf package;
      description = ''
          Packages to add to PATH for the Supafana process.
        '';
    };

    user = mkOption {
      description = "User to run Supafana process";
      default = "supafana";
      type = types.str;
    };
  };

  ###### Implementation

  config = mkIf cfg.enable {
    systemd.services.supafana = {
      path = cfg.packages;
      description = "Supafana service";
      after    = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        WorkingDirectory = cfg.workDir;
        User = cfg.user;
        EnvironmentFile = cfg.environmentFiles;
        ExecStart = "${cfg.package}/bin/supafana start";
        ExecStop = "${cfg.package}/bin/supafana stop";
        Restart = "always";
        ExecStartPre = let preScript = pkgs.writers.writeBashBin "supafanaStartPre" ''
            if [ ! -f ${cookieFile} ] || [ ! -s ${cookieFile} ]
            then
              echo "Creating cookie file"
              dd if=/dev/urandom bs=1 count=16 | ${pkgs.hexdump}/bin/hexdump -e '16/1 "%02x"' > ${cookieFile}
            fi
          '';
        in
          [ "${preScript}/bin/supafanaStartPre" ]
          ++ optional (cfg.migrateDb) "${cfg.package}/bin/supafana-ctl migrate";
      };
      environment = {
        RELEASE_TMP = cfg.workDir + "/tmp";
        RELEASE_COOKIE = cookieFile;
      } // cfg.environment;
    };
    systemd.tmpfiles.rules = [ "d ${cfg.workDir} 0700 ${cfg.user} - -" ];
    # Make the supafana commands available
    environment.systemPackages = [ cfg.package ];
    environment.variables = {
      RELEASE_COOKIE = cookieFile;
      RELEASE_TMP = cfg.workDir + "/tmp";
    };
  };
}
