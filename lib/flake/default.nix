###############################################################################
# Flake Utilities
# Host configuration utilities and helper functions
###############################################################################
{
  lib,
  pkgs,
  ...
}: let
  # Import individual modules
  shared = import ./shared.nix {inherit lib pkgs;};
  home = import ./home.nix {inherit lib pkgs;};
  system = import ./system.nix {inherit lib pkgs;};
in {
  # Export configuration functions
  inherit (shared) hostNames systemConfigs homeConfigs;
  inherit (home) mkHomeConfigurations;
  inherit (system) mkNixosConfigurations;
}
