{ stdenv, pkgs }:

with pkgs;
with stdenv;

let
  baseImage = callPackage ./base-image { };

in
{
  buildInputs = lib.optional isLinux [ conan nsis baseImage ];
}
