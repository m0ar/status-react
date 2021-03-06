# target-os = [ 'windows' 'linux' 'macos' 'android' 'ios' ]
{ pkgs ? import ((import <nixpkgs> { }).fetchFromGitHub {
    owner = "status-im";
    repo = "nixpkgs";
    rev = "15623aac6e8cbfa24d4268195bc8eda7303ea2ff";
    sha256 = "0crjmspk65rbpkl3kqcj7433355i9fy530lhc48g2cz75xjk4sxh";
  }) { config = { }; },
  target-os ? "" }:

with pkgs;
  let
    targetDesktop = {
      "linux" = true;
      "windows" = true;
      "macos" = true;
      "" = true;
    }.${target-os} or false;
    targetMobile = {
      "android" = true;
      "ios" = true;
      "" = true;
    }.${target-os} or false;
    # TODO: Try to use stdenv for iOS. The problem is with building iOS as the build is trying to pass parameters to Apple's ld that are meant for GNU's ld (e.g. -dynamiclib)
    _stdenv = if target-os == "ios" || target-os == "" then stdenvNoCC else stdenv;
    statusDesktop = callPackage ./scripts/lib/setup/nix/desktop { inherit target-os; stdenv = _stdenv; };
    statusMobile = callPackage ./scripts/lib/setup/nix/mobile { inherit target-os; stdenv = _stdenv; };
    nodeInputs = import ./scripts/lib/setup/nix/global-node-packages/output {
      # The remaining dependencies come from Nixpkgs
      inherit pkgs;
      inherit nodejs;
    };
    nodePkgs = [
      nodejs
      python27 # for e.g. gyp
      yarn
    ] ++ (map (x: nodeInputs."${x}") (builtins.attrNames nodeInputs));

  in _stdenv.mkDerivation rec {
    name = "env";
    env = buildEnv { name = name; paths = buildInputs; };
    buildInputs = with _stdenv; [
      bash
      clojure
      curl
      git
      jq
      leiningen
      lsof # used in scripts/start-react-native.sh
      maven
      ncurses
      ps # used in scripts/start-react-native.sh
      watchman
      unzip
      wget
    ] ++ nodePkgs
      ++ lib.optional isDarwin cocoapods
      ++ lib.optional targetDesktop statusDesktop.buildInputs
      ++ lib.optional targetMobile statusMobile.buildInputs;
    shellHook =
      ''
        set -e
      '' +
      lib.optionalString targetDesktop statusDesktop.shellHook +
      lib.optionalString targetMobile statusMobile.shellHook +
      ''
        if [ -n "$ANDROID_SDK_ROOT" ] && [ ! -d "$ANDROID_SDK_ROOT" ]; then
          ./scripts/setup # we assume that if the Android SDK dir does not exist, make setup needs to be run
        fi
        set +e
      '';
    hardeningDisable = statusDesktop.hardeningDisable;
  }
