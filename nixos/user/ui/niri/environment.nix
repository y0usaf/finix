{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    bayt.users."${config.user.name}".files.".config/niri/config.kdl".value = {
      debug = {
        dbus-interfaces-in-non-session-instances = {};
      };

      environment = {
        DISPLAY = ":0";
      };
    };
  };
}
