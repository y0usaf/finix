###############################################################################
# Home Manager Configuration
# Central configuration file for user-specific settings
# - Imports user modules from ./modules/home
# - Passes profile data down to modules
###############################################################################
{
  # Parameters provided to this configuration:
  config,
  pkgs,
  lib,
  inputs,
  profile, # Profile data containing user/system settings
  ...
}: {
  ###########################################################################
  # Module Import
  ###########################################################################

  # Import all modules from the ./modules/home directory.
  # The default.nix within that structure handles recursive imports.
  imports = [./modules/home];

  ###########################################################################
  # Module Configuration Passthrough
  ###########################################################################

  # Pass the entire 'profile.cfg' structure down to the imported modules.
  # Modules (like core.nix) can then access necessary configuration
  # values via 'config.cfg.*'.
  cfg = profile.cfg or {};

  # Note: Core settings like home.username, home.packages, dconf.enable
  # are now managed within nixos/modules/home/core/core.nix
}
