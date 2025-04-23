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

  # Minimal set of system settings merged with home configuration
  # This keeps explicit the small set of system values we actually need
  cfg = let
    # These specific system settings should be pulled into home configuration
    systemSettings = {
      # Core system attributes needed for identifying the user
      system = {
        username = hostSystem.cfg.system.username or null;
        homeDirectory = hostSystem.cfg.system.homeDirectory or null;
        hostname = hostSystem.cfg.system.hostname or null;
      };
      
      # Critical services that need to be activated in home config too
      core = {
        # SSH enable flag (needed for SSH config generation)
        ssh.enable = hostSystem.cfg.core.ssh.enable or false;
      };
    };
    
    # Get home configuration
    homeCfg = hostHome.cfg or {};
    
    # Start with minimal system settings, then override with home-specific settings
    mergedConfig = lib.recursiveUpdate systemSettings homeCfg;
  in mergedConfig;

  # Note: Core settings like home.username, home.packages, dconf.enable
  # are now managed within nixos/modules/home/core/core.nix
}
