{pkgs, lib, fetchgit, git, libsodium, glibcLocales, cmake, beamPackages} :
depsFile :

let
  LANG = "en_US.UTF-8";
  LOCALE_ARCHIVE = if pkgs.stdenv.isLinux then "${glibcLocales}/lib/locale/locale-archive" else "";

  inherit (beamPackages) fetchHex buildRebar3 buildMix pc hex;

  mkDeps = config: self:
    let
      deps = lib.mapAttrs (
        name: spec:
        build (spec // {
          src = fetch spec;
          beamDeps = with builtins;
            attrValues (intersectAttrs spec.deps self.deps);
        })
      ) config;
      sources = lib.mapAttrs (
        name: spec:
        fetch spec
      ) config;
    in { inherit deps sources; };

  build = spec :
    if spec.builder == "mix" then
      buildMix {
        inherit (spec) name version src beamDeps;
        # TODO: find a more general way to override deps individually. Libsodium needed by salty lib only.
        buildInputs = [ libsodium cmake ];
        inherit LANG LOCALE_ARCHIVE;
      }
    else if spec.builder == "rebar3" then
      buildRebar3 {
        inherit (spec) name version src beamDeps;
        buildInputs = [ git ];
        buildPlugins = [ pc ];
        inherit LANG LOCALE_ARCHIVE;
      }
    else
      abort "Unknown builder ${spec.builder}";

  fetch = spec :
    if spec.fetcher == "hex" then fetchHex {inherit (spec) pkg version sha256;}
    else if spec.fetcher == "git" then fetchgit {inherit (spec) url sha256 rev; leaveDotGit = true;}
    else abort "Unknown fetcher ${spec.fetcher}";

  mkConfig =
    # The sources, i.e. the attribute set of spec name to spec
    builtins.fromJSON (builtins.readFile depsFile);
in
lib.fix (mkDeps mkConfig)
