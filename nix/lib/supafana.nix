{ lib, beamPackages, mkMixDeps, gitignoreSource, libsodium, gawk}:

let
  inherit (mkMixDeps ../../server/deps.json) deps;
  pname = "supafana";
  version = lib.fileContents ../../server/VERSION;
  src = gitignoreSource ../../server;
  mixEnv = "prod";
  server = beamPackages.mixRelease {
    inherit (beamPackages) erlang elixir;
    inherit src pname version mixEnv;
    mixNixDeps = deps;
  };
in { inherit server deps; }
