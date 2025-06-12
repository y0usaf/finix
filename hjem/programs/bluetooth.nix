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

      # Shell integration with Bluetooth aliases
      ".zshrc".text = ''
        # Bluetooth aliases
        # GUI tools
        alias bt-manager="blueman-manager"
        alias bt-applet="blueman-applet"
        alias bt-adapters="blueman-adapters"
        alias bt-sendto="blueman-sendto"

        # CLI tools
        alias bt-status="bluetoothctl show"
        alias bt-devices="bluetoothctl devices"
        alias bt-scan="bluetoothctl scan on"
        alias bt-pair="bluetoothctl pair"
        alias bt-connect="bluetoothctl connect"
        alias bt-disconnect="bluetoothctl disconnect"
        alias bt-bluetuith="bluetuith"
      '';
    };
  };
}
