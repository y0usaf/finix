{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.home.ui.niri.enable {
    home.ui.niri.settings.output = {
      "DP-4" = {
        mode = "5120x1440@239.761";
        position = {
          x = 0;
          y = 0;
        };
      };
      "DP-2" = {
        mode = "5120x1440@239.761";
        position = {
          x = 0;
          y = 0;
        };
      };
      "HDMI-A-2" = {
        mode = "1920x1080@60.000";
        position = {
          x = 5120;
          y = 0;
        };
      };
    };
  };
}
