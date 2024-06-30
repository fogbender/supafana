{ pkgs, beamPackages, ... }:
let

  inherit (pkgs.lib) optional optionals;

  file-notifier = with pkgs;
    optional stdenv.isLinux libnotify # For ExUnit Notifier on Linux.
    ++ optional stdenv.isLinux inotify-tools # For file_system on Linux.
    ++ optional stdenv.isDarwin terminal-notifier # For ExUnit Notifier on macOS.
    ++ optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
      # For file_system on macOS.
      CoreFoundation
      CoreServices
    ]);


  inherit (beamPackages)
    rebar
    rebar3
    elixir
    erlang
    hex;

  elixir_libs = [
    erlang
    elixir
    hex
    rebar
    rebar3
  ];

  js_libs = with pkgs; [
    nodejs
    nodePackages.pnpm
  ];

in with pkgs; mkShell {
  buildInputs = [
    glibcLocales
    gnumake git which nix-universal-prefetch cacert
    libsodium
    jq
    cmake
    nix-tree
    dive
    just
    azure-cli bicep azure-storage-azcopy
    deploy-rs
    corepack_18
  ]
  ++ file-notifier
  ++ elixir_libs
  ++ js_libs;

  MIX_REBAR = "${rebar}/bin/rebar";
  MIX_REBAR3 = "${rebar3}/bin/rebar3";
  LOCALE_ARCHIVE = if stdenv.isLinux then "${glibcLocales}/lib/locale/locale-archive" else "";
  LANG = "en_US.UTF-8";
  LD_LIBRARY_PATH = lib.makeLibraryPath [ libsodium ];

  shellHook = ''
  if [ -f "./local.env" ]; then
  echo Sourcing local.env..
  . local.env
  fi
  '';
}
