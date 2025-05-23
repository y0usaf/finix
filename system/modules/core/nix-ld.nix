# This module configures Nix-LD.
{
  config,
  lib,
  pkgs,
  hostSystem,
  hostHome,
  ...
}: {
  config = {
    programs.nix-ld.enable = true;
  };
}
