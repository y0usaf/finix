###############################################################################
# Hyprland Window Rules Module (Hjem Version)
# Contains window management rules and layer rules
###############################################################################
_:
###########################################################################
# Window Rules Configuration
###########################################################################
{
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
}
