{
  config,
  lib,
  ...
}: let
  cfg = config.home.ui.niri;
in {
  config = lib.mkIf cfg.enable {
    home.ui.niri.settings = {
      debug = {
        wait-for-frame-completion-in-pipewire = {};
        dbus-interfaces-in-non-session-instances = {};
      };

      environment = {
        DISPLAY = ":0";
      };
    };
  };
}
