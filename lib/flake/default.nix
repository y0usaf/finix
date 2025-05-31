###############################################################################
# Flake Utilities
# Host configuration utilities and helper functions
###############################################################################
{
  lib,
  pkgs,
  helpers,
  ...
}: let
  # Import individual modules
  shared = import ./shared.nix {inherit lib pkgs helpers;};
  home = import ./home.nix {inherit lib pkgs helpers;};
  system = import ./system.nix {inherit lib pkgs helpers;};
in {
  # Export configuration functions
  inherit (shared) hostNames systemConfigs homeConfigs;
  inherit (home) mkHomeConfigurations;
  inherit (system) mkNixosConfigurations;
}
