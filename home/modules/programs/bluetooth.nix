###############################################################################
# Bluetooth Program Module
# Configure Bluetooth UI tools and utilities
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}: let
  cfg = config.cfg.programs.bluetooth;
in {
  # Options
  options.cfg.programs.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth user tools";
  };

  # Implementation
  config = lib.mkIf cfg.enable {
    # Install Bluetooth GUI and tools
    home.packages = with pkgs; [
      # Main Bluetooth GUI manager
      blueman

      # Additional Bluetooth utilities
      bluetuith # TUI Bluetooth manager
    ];

    # Configure autostart for Blueman applet
    xdg.configFile."autostart/blueman.desktop".source = "${pkgs.blueman}/etc/xdg/autostart/blueman.desktop";

    # Convenient shell aliases for Bluetooth management
    programs.zsh.shellAliases = {
      # GUI tools
      bt-manager = "blueman-manager";
      bt-applet = "blueman-applet";
      bt-adapters = "blueman-adapters";
      bt-sendto = "blueman-sendto";

      # CLI tools
      bt-status = "bluetoothctl show";
      bt-devices = "bluetoothctl devices";
      bt-scan = "bluetoothctl scan on";
      bt-pair = "bluetoothctl pair";
      bt-connect = "bluetoothctl connect";
      bt-disconnect = "bluetoothctl disconnect";
      bt-bluetuith = "bluetuith";
    };
  };
}
