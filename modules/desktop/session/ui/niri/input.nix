{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    manzil.users."${config.user.name}".files.".config/niri/config.kdl".value.input = {
      keyboard = {
        xkb = {
          layout = "us";
        };
      };
      touchpad = {
        tap = {};
        natural-scroll = {};
        accel-speed = 0.0;
      };
      mouse = {
        accel-speed = 0.0;
      };
      warp-mouse-to-focus = {};
      focus-follows-mouse._props.max-scroll-amount = "0%";
      mod-key = "Alt";
    };
  };
}
