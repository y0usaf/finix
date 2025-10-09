{
  config,
  lib,
  genLib,
  ...
}: let
  monitorsConfig = {
    monitor = [
      "DP-4,highres@highrr,0x0,1"
      "DP-3,highres@highrr,0x0,1"
      "DP-2,5120x1440@239.76,0x0,1"
      "DP-1,5120x1440@239.76,0x0,1"
      "eDP-1,1920x1080@300.00,0x0,1"
    ];
  };
in {
  config = lib.mkIf config.user.ui.hyprland.enable {
    usr.files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkAfter (genLib.toHyprconf {
        attrs = monitorsConfig;
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
