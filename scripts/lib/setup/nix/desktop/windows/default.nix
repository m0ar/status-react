{ stdenv, pkgs }:

with pkgs;
with stdenv;

let
  baseImage = callPackage ./base-image { };

in
{
  buildInputs = lib.optional isLinux [ conan nsis baseImage ];

  shellHook = ''
    export STATUSREACT_WINDOWS_BASEIMAGE_PATH="${baseImage}/src"
  '';
}
