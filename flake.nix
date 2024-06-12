{
  description = "EMBS flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    utils.url = "github:numtide/flake-utils";

    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, utils, unstable, gitignore }:
    let
      inherit (nixpkgs.lib) filterAttrs const;
      inherit (builtins) readDir mapAttrs;

      overlay = final: prev: {
        inherit (gitignore.lib) gitignoreSource;
        unstable = unstable.legacyPackages.${final.system};
        # TODO switch to beam_nox.packages.erlang_26 when available in nix cache
        beamPackages = final.unstable.beam_minimal.packages.erlang_26.extend(new: old: {
          rebar3 = old.rebar3.overrideAttrs{ doCheck = false; };
        });
        mkMixDeps = final.callPackage ./nix/lib/mk-mix-deps.nix { };
        embs = final.callPackage ./nix/lib/embs.nix { };
      };

      sysPkgs = (system :
        import nixpkgs {
          inherit system;
          overlays = [
            overlay
          ];
        }
      );

      pkgEmbs = (system:
        let pkgs = sysPkgs system;
        in pkgs.embs.server
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
          embs = pkgEmbs system;
        in
          pkgs.dockerTools.streamLayeredImage {
            name = "embs";
            tag = "latest";
            contents = [ coreutils bash embs ];
            config = {
              Env = [
                "RELEASE_COOKIE=TEST"
                "ELIXIR_ERL_OPTIONS=+fnu"
              ];
              Cmd = [ "bash" "${embs}/bin/start.sh" ];
              Volumes = { "/tmp" = { }; };
              ExposedPorts = { "80" = { }; };
            };
          }
      );
    in
    {
      devShells.x86_64-linux = shells "x86_64-linux";
      devShells.x86_64-darwin = shells "x86_64-darwin";
      devShells.aarch64-darwin = shells "aarch64-darwin";

      packages.x86_64-linux.default = self.packages.x86_64-linux.embs;
      packages.x86_64-linux.dockerImage = buildDockerImage "x86_64-linux";

      packages.x86_64-linux.embs = pkgEmbs "x86_64-linux";
      packages.x86_64-darwin.embs = pkgEmbs "x86_64-darwin";
      packages.aarch64-darwin.embs = pkgEmbs "aarch64-darwin";

      overlays.default = overlay;
    };
}
