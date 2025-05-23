###############################################################################
# Sway Launcher Desktop Module
# A simple application launcher for Sway using fzf
# - Provides a desktop application launcher script
# - Symlinks the launcher script to ~/.config/scripts
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.programs.sway-launcher-desktop;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.programs.sway-launcher-desktop = {
    enable = lib.mkEnableOption "sway launcher desktop";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      fzf
    ];

    ###########################################################################
    # Configuration Files
    ###########################################################################
    xdg.configFile."scripts/sway-launcher-desktop.sh" = {
      source = ../../../lib/scripts/sway-launcher-desktop.sh;
      executable = true;
    };
  };
}
