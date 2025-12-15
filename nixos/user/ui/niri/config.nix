{
  config,
  pkgs,
  lib,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    environment.systemPackages = [
      pkgs.niri
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard-rs
      pkgs.jq
      pkgs.swaybg
      pkgs.xwayland-satellite
    ];

    usr.files.".config/niri/config.kdl" = {
      clobber = true;
      generator = genLib.toNiriconf;
      value =
        {
          # Include wallust-generated border colors (live-reloads on wallpaper change)
          include._args = ["/home/${config.user.name}/.cache/wallust/niri-borders.kdl"];

          prefer-no-csd = {};

          cursor = {
            xcursor-theme = "DeepinDarkV20-x11";
            xcursor-size = config.user.appearance.cursorSize;
          };

          screenshot-path = null;

          spawn-at-startup =
            [
              ["${pkgs.xwayland-satellite}/bin/xwayland-satellite"]
              ["sh" "-c" "swaybg -i $(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1) -m fill"]
              ["${pkgs.vicinae}/bin/vicinae" "server"]
            ]
            ++ lib.optional (config.user.ui.ags.enable or false) ["sh" "-c" "${config.user.ui.ags.package}/bin/ags run /home/${config.user.name}/.config/ags/bar-overlay.tsx"];

          hotkey-overlay = {};
          window-rule = {
            match._props.app-id = "^launcher$";
            default-column-width.fixed = 800;
            default-window-height.fixed = 600;
          };
        }
        // lib.optionalAttrs (config.user.ui.niri.extraConfig != "") {
          _extraConfig = config.user.ui.niri.extraConfig;
        };
    };
  };
}
