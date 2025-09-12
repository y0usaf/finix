{
  config,
  lib,
  genLib,
  ...
}: let
  cfg = config.home.ui.hyprland;

  windowRulesConfig = {
    "$firefox-pip" = "class:^(firefox)$, title:^(Picture-in-Picture)";
    "$kitty" = "class:^(kitty)$";
    windowrulev2 = [
      "float, center, size 300 600, class:^(launcher)"
      "float, center, class:^(hyprland-share-picker)"
      "float, $firefox-pip"
      "opacity 0.75 override, $firefox-pip"
      "noborder, $firefox-pip"
      "size 30% 30%, $firefox-pip"
      "workspace special:lovely, title:^(Lovely.*)"
    ];
    layerrule = [
      "blur, notifications"
    ];
  };
in {
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkAfter (genLib.toHyprconf {
        attrs = windowRulesConfig;
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
