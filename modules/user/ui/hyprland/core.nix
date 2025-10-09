{
  config,
  lib,
  hostConfig,
  genLib,
  ...
}: let
  coreConfig = {
    "$active_colour" = "ffffffff";
    "$transparent" = "ffffff00";
    "$inactive_colour" = "333333ff";
    bezier = [
      "in_out,.65,-0.01,0,.95"
      "woa,0,0,0,1"
    ];
    general = {
      gaps_in = 10;
      gaps_out = 5;
      border_size = 1;
      "col.active_border" = "rgba($active_colour)";
      "col.inactive_border" = "rgba($inactive_colour)";
      layout =
        if config.user.ui.hyprland.group.enable
        then "group"
        else "dwindle";
    };
    dwindle = {
      single_window_aspect_ratio = "1.77 1.0";
      single_window_aspect_ratio_tolerance = 0.1;
    };
    input = {
      kb_layout = "us";
      follow_mouse = 1;
      sensitivity = -1.0;
      force_no_accel = true;
      mouse_refocus = false;
    };
    decoration = {
      rounding = 0;
      blur = {
        enabled = true;
        size = 10;
        passes = 3;
        ignore_opacity = true;
        popups = true;
      };
    };
    render = {
      cm_enabled = 0;
    };
    animations = {
      enabled =
        if config.user.core.appearance.animations.enable
        then 1
        else 0;
      animation = [
        "windows,1,2,woa,popin"
        "border,1,10,default"
        "fade,1,10,default"
        "workspaces,1,5,in_out,slide"
      ];
    };
    misc = {
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
    };
    debug.disable_logs = false;
    env =
      [
        "HYPRCURSOR_THEME,DeepinDarkV20-hypr"
        "HYPRCURSOR_SIZE,${toString config.user.core.appearance.cursorSize}"
        "XCURSOR_THEME,DeepinDarkV20-x11"
        "XCURSOR_SIZE,${toString config.user.core.appearance.cursorSize}"
      ]
      ++ lib.optionals hostConfig.hardware.nvidia.enable [
        "LIBVA_DRIVER_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      ];
  };
in {
  config = lib.mkIf config.user.ui.hyprland.enable {
    usr.files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkAfter (genLib.toHyprconf {
        attrs = coreConfig;
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
