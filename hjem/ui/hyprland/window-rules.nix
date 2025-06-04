###############################################################################
# Hyprland Window Rules Module (Hjem Version)
# Contains window management rules and layer rules
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
  options.cfg.hjome.ui.hyprland.windowRules = lib.mkOption {
    type = lib.types.attrs;
    internal = true;
    default = {};
    description = "Hyprland window rules configuration attributes";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    cfg.hjome.ui.hyprland.windowRules = {
      ###########################################################################
      # Application Shortcut Variables
      ###########################################################################
      "$firefox-pip" = "class:^(firefox)$, title:^(Picture-in-Picture)";
      "$kitty" = "class:^(kitty)$";

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
        "workspace special:lovely, title:^(Lovely.*)"
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