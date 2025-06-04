###############################################################################
# Hyprland Monitor Configuration Module (Hjem Version)
# Contains monitor setup and display configuration
###############################################################################
{
  config,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.ui.hyprland;
in {
  ###########################################################################
  # Internal Configuration Storage
  ###########################################################################
  options.cfg.hjome.ui.hyprland.monitors = lib.mkOption {
    type = lib.types.attrs;
    internal = true;
    default = {};
    description = "Hyprland monitor configuration attributes";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    cfg.hjome.ui.hyprland.monitors = {
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