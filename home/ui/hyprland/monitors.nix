###############################################################################
# Hyprland Monitor Configuration Module
# Contains monitor setup and display configuration
###############################################################################
{
  config,
  lib,
  ...
}: let
  cfg = config.cfg.ui.hyprland;
in {
  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      ###########################################################################
      # Monitor & Display Settings
      ###########################################################################
      monitor = [
        "DP-4,highres@highrr,0x0,1"
        "DP-3,highres@highrr,0x0,1"
        "DP-2,5120x1440@239.76,0x0,1"
        "eDP-1,1920x1080@300.00,0x0,1"
      ];
    };
  };
}
