###############################################################################
# Bluetooth Program Module (Maid Version)
# Configure Bluetooth UI tools and utilities
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.bluetooth;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.programs.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth user tools";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      # Main Bluetooth GUI manager
      blueman

      # Additional Bluetooth utilities
      bluetuith # TUI Bluetooth manager
    ];

    ###########################################################################
    # Configuration Files
    ###########################################################################
    users.users.y0usaf.maid.file.xdg_config."autostart/blueman.desktop".source = "${pkgs.blueman}/etc/xdg/autostart/blueman.desktop";
  };
}
