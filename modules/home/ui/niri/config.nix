{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.ui.niri;
  agsEnabled = config.home.ui.ags.enable or false;

  # Import local generators
  generators = import ../../../../lib/generators {inherit lib;};
in {
  config = lib.mkIf cfg.enable {
    home.ui.niri.settings = {
      prefer-no-csd = {};

      cursor = {
        xcursor-theme = "DeepinDarkV20-x11";
        xcursor-size = config.home.core.appearance.cursorSize;
      };

      screenshot-path = null;

      spawn-at-startup =
        [
          ["${pkgs.xwayland-satellite}/bin/xwayland-satellite"]
          ["sh" "-c" "swaybg -i $(find ${config.home.directories.wallpapers.static.path} -type f | shuf -n 1) -m fill"]
        ]
        ++ lib.optional agsEnabled ["${pkgs.ags}/bin/ags" "run" "/home/${config.user.name}/.config/ags/bar-overlay.tsx"];

      hotkey-overlay = {};
      window-rule = {};
    };

    hjem.users.${config.user.name} = {
      packages = [
        pkgs.niri
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.jq
        pkgs.swaybg
      ];
      files = {
        ".config/niri/config.kdl" = {
          clobber = true;
          generator = generators.toNiriconf;
          value =
            cfg.settings
            // lib.optionalAttrs (cfg.extraConfig != "") {
              _extraConfig = cfg.extraConfig;
            };
        };
      };
    };
  };
}
