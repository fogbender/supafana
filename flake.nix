{
  description = "Supafana flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";

    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = inputs@{ self, nixpkgs, gitignore, deploy-rs, sops-nix }:
    let
      system = "x86_64-linux";
      inherit (nixpkgs.lib) filterAttrs const;
      inherit (builtins) readDir mapAttrs;

      overlay = final: prev: {
        inherit (gitignore.lib) gitignoreSource;
        beamPackages = final.beam.packages.erlang.extend(new: old: {
          rebar3 = old.rebar3.overrideAttrs{ doCheck = false; };
        });
        mkMixDeps = final.callPackage ./nix/lib/mk-mix-deps.nix { };
        supafana = final.callPackage ./nix/lib/supafana.nix { };
      };

      sysPkgs = (system :
        import nixpkgs {
          inherit system;
          overlays = [
            overlay
          ];
        }
      );

      nixosSystem = (system: args:
        let
          pkgs = sysPkgs system;
        in
          nixpkgs.lib.nixosSystem ({
            inherit pkgs system;
            specialArgs = { inherit inputs; };
          } // args)
      );

      azureImage = (system: args:
        let img = nixosSystem system args;
        in img.config.system.build.azureImage
      );

      deployPkgs = import nixpkgs {
        inherit system;
        overlays = [
          deploy-rs.overlay
          (self: super: { deploy-rs = { inherit (sysPkgs system) deploy-rs; lib = super.deploy-rs.lib; }; })
        ];
      };

      pkgSupafana = (system:
        let pkgs = sysPkgs system;
        in pkgs.supafana.server
      );

      shells = (system:
        let s = mapAttrs
          (path: _: (let pkgs = sysPkgs system; in pkgs.callPackage (./nix/shells + "/${path}") {  }))
          (filterAttrs (_: t: t == "directory") (readDir ./nix/shells));
        in s // { default = s.dev; } );

      buildDockerImage = (system:
        let
          pkgs = sysPkgs system;
          inherit (pkgs) coreutils bash;
          supafana = pkgSupafana system;
        in
          pkgs.dockerTools.streamLayeredImage {
            name = "supafana";
            tag = "latest";
            contents = [ coreutils bash supafana ];
            config = {
              Env = [
                "RELEASE_COOKIE=TEST"
                "ELIXIR_ERL_OPTIONS=+fnu"
              ];
              Cmd = [ "bash" "${supafana}/bin/start.sh" ];
              Volumes = { "/tmp" = { }; };
              ExposedPorts = { "80" = { }; };
            };
          }
      );

      supafanaAzureImage = system: azureImage system {
        modules = [ nix/modules/azure-image/image.nix nix/modules/supafana-base ];
      };

      grafanaAzureImage = system: azureImage system {
        modules = [ nix/modules/azure-image/image.nix nix/hosts/grafana ];
      };

    in
    {
      devShells.x86_64-linux = shells "x86_64-linux";
      devShells.x86_64-darwin = shells "x86_64-darwin";
      devShells.aarch64-darwin = shells "aarch64-darwin";

      packages.x86_64-linux.default = self.packages.x86_64-linux.supafana;
      packages.x86_64-linux.dockerImage = buildDockerImage "x86_64-linux";

      packages.x86_64-linux.supafana = pkgSupafana "x86_64-linux";
      packages.x86_64-darwin.supafana = pkgSupafana "x86_64-darwin";
      packages.aarch64-darwin.supafana = pkgSupafana "aarch64-darwin";

      overlays.default = overlay;

      packages.x86_64-linux.supafana-image = supafanaAzureImage "x86_64-linux";
      packages.x86_64-linux.grafana-image = grafanaAzureImage "x86_64-linux";

      nixosConfigurations = {
        supafana-test = nixosSystem system {
          modules = [ nix/hosts/supafana-test.nix ];
        };
        grafana = nixosSystem system {
          modules = [ nix/hosts/grafana ];
        };
      };

      deploy = {
        sshUser = "admin";
        user = "root";
        nodes = {
          supafana-test = {
            hostname = "supafana-test.com";
            profiles.system.path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.supafana-test;
          };
          grafana-mk = {
            hostname = "iclisqzkhfgcvlrvqbal.supafana.local";
            profiles.system.path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.grafana;
          };
        };
      };
    };
}
