{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.hyprland.enable {
    bayt.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
      text = lib.mkAfter (config.lib.generators.toHyprconf {
        attrs = {
          monitor = [
            "DP-4,5120x1440@239.761,0x0,1"
            "DP-2,5120x1440@239.761,0x0,1"
            "HDMI-A-2,1920x1080@60.000,5120x0,1"
          ];
        };
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
