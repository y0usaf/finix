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
    home.activation.symlinkSwayLauncherDesktop = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create scripts directory
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${config.xdg.configHome}/scripts"

      # Symlink the launcher script
      $DRY_RUN_CMD ln -sf $VERBOSE_ARG "$HOME/nixos/lib/scripts/sway-launcher-desktop.sh" "${config.xdg.configHome}/scripts/sway-launcher-desktop.sh"
    '';
  };
}
