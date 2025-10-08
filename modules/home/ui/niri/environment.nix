{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.home.ui.niri.enable {
    home.ui.niri.settings = {
      debug = {
        dbus-interfaces-in-non-session-instances = {};
      };

      environment = {
        DISPLAY = ":0";
      };
    };
  };
}
