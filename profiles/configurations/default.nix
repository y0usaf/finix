###############################################################################
# NixOS System Configuration
# Complete system configuration through modular imports
# All configuration details are defined in the modules/system directory
###############################################################################
{
  # The following variables are injected by the NixOS module system:
  #   - config: The cumulative system configuration.
  #   - lib: Library functions for list manipulation, options handling, etc.
  #   - pkgs: The collection of available Nix packages.
  #   - profile: A user-defined profile specifying many system preferences.
  #   - inputs: External inputs (like additional packages or modules).
  #   - ...: Any extra parameters.
  config,
  lib,
  pkgs,
  profile,
  inputs,
  ...
}: {
  ###########################################################################
  # Module Imports
  # Import all system configuration modules
  ###########################################################################
  imports = [
    # Core system modules
    ../../modules/system/core.nix
    ../../modules/system/boot.nix
    ../../modules/system/hardware.nix
    ../../modules/system/services.nix
    ../../modules/system/security.nix
    ../../modules/system/programs.nix
    ../../modules/system/users.nix
    ../../modules/system/network.nix
    ../../modules/system/env.nix
    ../../modules/system/nvidia.nix
  ];

  config = {
    ###########################################################################
    # Environment Variables
    # System profile identification
    ###########################################################################
    environment.variables = {
      NIXOS_PROFILE = "y0usaf-desktop";
    };
  };
}
