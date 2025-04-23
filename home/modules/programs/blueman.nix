###############################################################################
# Blueman - Bluetooth Manager Module
# Configures the Blueman Bluetooth management interface
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}: let
  cfg = config.cfg.programs.blueman;
in {
  options.cfg.programs.blueman = {
    enable = lib.mkEnableOption "Blueman Bluetooth manager";
  };
  
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [blueman];
    
    # Autostart Blueman applet in desktop sessions if system Bluetooth is enabled
    xdg.configFile = lib.mkIf (hostSystem.cfg.hardware.bluetooth.enable or false) {
      "autostart/blueman.desktop".source = "${pkgs.blueman}/etc/xdg/autostart/blueman.desktop";
    };
    
    # Add convenient shell aliases
    programs.zsh.shellAliases = {
      bt-manager = "blueman-manager";
      bt-connect = "blueman-manager";
    };
  };
}