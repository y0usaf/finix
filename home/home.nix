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
  # Module Configuration Passthrough
  ###########################################################################

  # Selectively pull in system settings and merge with home configuration
  # This allows reusing system settings while maintaining separation
  cfg = let
    # These specific system settings should be pulled into home configuration
    systemSettings = {
      # Core system attributes (username, hostname, etc.)
      system = hostSystem.cfg.system or {};
      
      # Pull hardware-related settings from system
      core = {
        # NVIDIA/CUDA settings (hardware-specific)
        nvidia = hostSystem.cfg.core.nvidia or {};
        
        # SSH enable flag (used by both system and home)
        ssh.enable = hostSystem.cfg.core.ssh.enable or false;
      };
    };
    
    # Get home configuration
    homeCfg = hostHome.cfg or {};
    
    # Start with system settings, then override with home-specific settings
    # This way home settings take precedence when both exist
    mergedConfig = lib.recursiveUpdate systemSettings homeCfg;
  in mergedConfig;

  # Note: Core settings like home.username, home.packages, dconf.enable
  # are now managed within nixos/modules/home/core/core.nix
}
