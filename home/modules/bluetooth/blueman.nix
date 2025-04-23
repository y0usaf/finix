###############################################################################
# Blueman - Bluetooth Manager Module
# Configures the Blueman Bluetooth management interface
# - Bluetooth device management UI
# - System tray applet
# - Depends on system-level Bluetooth being enabled
###############################################################################
{
  config,
  pkgs,
  lib,
  hostSystem,
  ...
}: let
  cfg = config.cfg.bluetooth.blueman;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.bluetooth.blueman = {
    enable = lib.mkEnableOption "Blueman Bluetooth manager";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf (cfg.enable && (hostSystem.cfg.hardware.bluetooth.enable or false)) {
    # Add Blueman to user packages
    home.packages = with pkgs; [
      blueman
    ];
    
    # Autostart Blueman applet in desktop sessions
    xdg.configFile."autostart/blueman.desktop".source = "${pkgs.blueman}/etc/xdg/autostart/blueman.desktop";
    
    # Add convenient shell aliases
    programs.zsh.shellAliases = {
      bt-manager = "blueman-manager";
      bt-connect = "blueman-manager";
    };
    
    # Include Bluetooth in shell environment
    home.sessionVariables = {
      BLUETOOTH_ENABLED = "1";
    };
  };
}