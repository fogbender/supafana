{ pkgs, supafana, beamPackages, writeScriptBin, lib, ... }:
let
  js_libs = with pkgs; [
    nodejs
    nodePackages.pnpm
  ];

  link-deps = writeScriptBin "link-deps.sh" ''
    mkdir -p _build/test/lib
    ${lib.concatMapStrings
      (dep: "${./mix-link-dep.sh} ${dep}\n")
      (builtins.attrValues supafana.deps)}
  '';
in with pkgs; mkShell {
  inputsFrom = [ supafana.server ];

  buildInputs = [
    glibcLocales
    gnumake git
    libsodium
    link-deps
    js_libs
  ];

  MIX_REBAR = "${rebar}/bin/rebar";
  MIX_REBAR3 = "${rebar3}/bin/rebar3";
  MIX_ENV = "test";
  LOCALE_ARCHIVE = if stdenv.isLinux then "${glibcLocales}/lib/locale/locale-archive" else "";
  LANG = "en_US.UTF-8";
}
