###############################################################################
# Bluetooth Program Module (Hjem Version)
# Configure Bluetooth UI tools and utilities
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.hjome.programs.bluetooth;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.programs.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth user tools";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      # Main Bluetooth GUI manager
      blueman

      # Additional Bluetooth utilities
      bluetuith # TUI Bluetooth manager
    ];

    ###########################################################################
    # Configuration Files
    ###########################################################################
    files = {
      # Configure autostart for Blueman applet
      ".config/autostart/blueman.desktop".source = "${pkgs.blueman}/etc/xdg/autostart/blueman.desktop";
    };
  };
}
