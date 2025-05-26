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
        "float, mouse, size 300 300, title:^(Smile)"
        "float, center, class:^(hyprland-share-picker)"
        "float, class:^(ags)$ title:^(system-stats)$"
        "center, class:^(ags)$ title:^(system-stats)$"
        "float, $firefox-pip"
        "opacity 0.75 override, $firefox-pip"
        "noborder, $firefox-pip"
        "size 30% 30%, $firefox-pip"
        # Hide Lovely mod injector window
        "workspace special:hidden, title:^(Lovely.*)"
      ];

      ###########################################################################
      # Layer Rules
      ###########################################################################
      layerrule = [
        "blur, notifications"
        "blur, fabric"
      ];
    };
  };
}