###############################################################################
# Configuration Merge Module
# Minimal merging of essential system data with home configuration
# - Only takes username and homeDirectory from system (bare minimum for Home Manager)
# - Merges with home-specific configuration
###############################################################################
{
  lib,
  config,
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
        username = config.cfg.shared.username or null;
        homeDirectory = config.cfg.shared.homeDirectory or null;
      };
    };

    # Get home configuration
    homeCfg = hostHome.cfg or {};

    # Merge essential system settings with home-specific settings
    mergedConfig = lib.recursiveUpdate essentialSystemSettings homeCfg;
  in
    mergedConfig;
}
