###############################################################################
# Flake Utilities
# Host configuration utilities and helper functions
###############################################################################
{
  lib,
  pkgs,
  ...
}: let
  # Import system configuration utilities (no shared dependencies)
  system = import ./system.nix {inherit lib pkgs;};
in {
  # Export configuration functions
  inherit (system) mkNixosConfigurations;
}
