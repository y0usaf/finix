{
  config,
  lib,
  ...
}: let
  cfg = config.home.ui.niri;
in {
  config = lib.mkIf cfg.enable {
    home.ui.niri.settings.input = {
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
