{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.sway.enable {
    bayt.users."${config.user.name}".files.".config/sway/config".text = lib.mkAfter ''
      input type:keyboard {
          xkb_layout us
      }

      input type:touchpad {
          tap enabled
          natural_scroll enabled
          accel_profile flat
          pointer_accel 0
      }

      input type:pointer {
          accel_profile flat
          pointer_accel 0
      }

      focus_follows_mouse yes
      mouse_warping none
    '';
  };
}
