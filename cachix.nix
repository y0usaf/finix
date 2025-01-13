#===============================================================================
#
#                     Cachix Configuration
#
# Description:
#     Configuration file for Cachix binary cache management. Handles:
#     - Binary cache imports
#     - Cache substituters
#     - Trust settings
#     Note: This file is automatically managed by cachix
#
# Author: y0usaf
# Last Modified: 2025
#
#===============================================================================
{
  pkgs,
  lib,
  ...
}: let
  folder = ./cachix;
  toImport = name: value: folder + ("/" + name);
  filterCaches = key: value: value == "regular" && lib.hasSuffix ".nix" key;
  imports = lib.mapAttrsToList toImport (lib.filterAttrs filterCaches (builtins.readDir folder));
in {
  inherit imports;
  # nix.settings.substituters = ["https://cache.nixos.org/"];
}
