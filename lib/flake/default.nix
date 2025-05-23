###############################################################################
# Flake Utilities
# Uses import-modules.nix pattern for automatic discovery and merging
###############################################################################
{
  lib,
  pkgs,
  ...
}: let
  # Get all .nix files in the current directory (excluding default.nix)
  moduleFiles = (import ../../lib/helpers/import-modules.nix {inherit lib;}) ./.;

  # Import each module and collect the attribute sets
  imports = map (path: import path {inherit lib pkgs;}) moduleFiles;

  # Merge all attribute sets together
  mergeAttrs = builtins.foldl' (acc: attrs: acc // attrs) {};
in
  mergeAttrs imports
