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
      pkgs.wl-clipboard
      pkgs.jq
      pkgs.swaybg
    ];

    usr.files.".config/niri/config.kdl" = {
      clobber = true;
      generator = genLib.toNiriconf;
      value =
        {
          prefer-no-csd = {};

          cursor = {
            xcursor-theme = "DeepinDarkV20-x11";
            xcursor-size = config.user.core.appearance.cursorSize;
          };

          screenshot-path = null;

          spawn-at-startup =
            [
              ["${pkgs.xwayland-satellite}/bin/xwayland-satellite"]
              ["sh" "-c" "swaybg -i $(find ${config.user.directories.wallpapers.static.path} -type f | shuf -n 1) -m fill"]
            ]
            ++ lib.optional (config.user.ui.ags.enable or false) ["${pkgs.ags}/bin/ags" "run" "/home/${config.user.name}/.config/ags/bar-overlay.tsx"];

          hotkey-overlay = {};
          window-rule = {
            match._props.app-id = "^launcher$";
            default-column-width.fixed = 800;
            default-window-height.fixed = 600;
          };
        }
        // lib.optionalAttrs (config.user.ui.niri.extraConfig != "") {
          inherit (config.user.ui.niri) extraConfig;
        };
    };
  };
}
