###############################################################################
# Home Manager Configuration
# Central configuration file for user-specific settings
# - Imports user modules from ./modules/home
# - Passes host data down to modules
###############################################################################
{
  # Parameters provided to this configuration:
  config,
  pkgs,
  lib,
  inputs,
  hostSystem, # System-specific host data
  hostHome,   # Home-specific host data
  ...
}: {
  ###########################################################################
  # Module Import
  ###########################################################################

  # Import all modules from the ./modules directory.
  # The default.nix within that structure handles recursive imports.
  imports = [./modules];

  ###########################################################################
  # Module Configuration
  ###########################################################################

  # Use home-specific configuration only
  # System settings should be accessed directly via hostSystem.cfg when needed
  # This provides a cleaner separation between system and home configurations
  cfg = hostHome.cfg or {};

  # Note: Core settings like home.username, home.packages, dconf.enable
  # are now managed within nixos/modules/home/core/core.nix
}
