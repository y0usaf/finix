inputs: let
  lib = inputs.nixpkgs.lib;
  moduleFiles = (import ../../../lib/helpers/import-modules.nix {inherit lib;}) ./.;
  modules = map (file: import file inputs) moduleFiles;
  mergedOutputs = lib.foldl' lib.recursiveUpdate {} modules;
in
  mergedOutputs