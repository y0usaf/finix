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
  hjem = import ./hjem.nix {inherit lib pkgs helpers;};
in {
  # Export configuration functions
  inherit (shared) hostNames systemConfigs homeConfigs hjemConfigs validHostNames mkSpecialArgs mapToAttrs;
  inherit (home) mkHomeConfigurations;
  inherit (system) mkNixosConfigurations;
  inherit (hjem) flakeOutputs mkHjemConfigurations;
}
