###############################################################################
# Firefox Main Configuration Module
# Module options and basic configuration
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.programs.firefox = {
    enable = lib.mkEnableOption "Firefox browser with optimized settings";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf config.home.programs.firefox.enable {
    # This module provides the central option definition and can include
    # any shared configuration that doesn't fit into the other modules
  };
}
