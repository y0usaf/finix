{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    usr.files.".config/niri/config.kdl".value = {
      debug = {
        dbus-interfaces-in-non-session-instances = {};
      };

      environment = {
        DISPLAY = ":0";
      };
    };
  };
}
