###############################################################################
# Configuration Merge Module
# Minimal merging of essential system data with home configuration
# - Only takes username and homeDirectory from system (bare minimum for Home Manager)
# - Merges with home-specific configuration
###############################################################################
{
  lib,
  hostSystem ? {},
  hostHome ? {},
  ...
}: {
  ###########################################################################
  # Minimal Configuration Merge
  ###########################################################################

  cfg = let
    # Only the absolute essentials from system config
    essentialSystemSettings = {
      system = {
        username = hostSystem.cfg.system.username or null;
        homeDirectory = hostSystem.cfg.system.homeDirectory or null;
      };
    };

    # Get home configuration
    homeCfg = hostHome.cfg or {};

    # Merge essential system settings with home-specific settings
    mergedConfig = lib.recursiveUpdate essentialSystemSettings homeCfg;
  in
    mergedConfig;
}
