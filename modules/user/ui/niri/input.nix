{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    usr.files.".config/niri/config.kdl".value.input = {
      keyboard = {
        xkb = {
          layout = "us";
        };
      };
      touchpad = {
        tap = {};
        dwt = {};
        natural-scroll = {};
        accel-speed = 0.0;
      };
      mouse = {
        accel-speed = 0.0;
      };
      focus-follows-mouse = {
        _props = {"max-scroll-amount" = "0%";};
      };
      mod-key = "Alt";
    };
  };
}
