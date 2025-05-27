###############################################################################
# Hyprland Window Rules Module
# Contains window management rules and layer rules
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
      # Application Shortcut Variables
      ###########################################################################
      "$firefox-pip" = "class:^(firefox)$, title:^(Picture-in-Picture)";

      ###########################################################################
      # Window Management Rules
      ###########################################################################
      windowrulev2 = [
        "float, center, size 300 600, class:^(launcher)"
        "float, center, class:^(hyprland-share-picker)"
        "float, $firefox-pip"
        "opacity 0.75 override, $firefox-pip"
        "noborder, $firefox-pip"
        "size 30% 30%, $firefox-pip"
        # Move Lovely mod injector to special workspace
        "workspace special, title:^(Lovely.*)"
      ];

      ###########################################################################
      # Layer Rules
      ###########################################################################
      layerrule = [
        "blur, notifications"
      ];
    };
  };
}
