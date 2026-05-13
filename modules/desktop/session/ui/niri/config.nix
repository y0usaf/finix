{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    environment.systemPackages = [
      flakeInputs.niri.packages."${pkgs.stdenv.hostPlatform.system}".default
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard-rs
      pkgs.jq
      pkgs.swaybg
      pkgs.xwayland-satellite
    ];

    manzil.users."${config.user.name}".files.".config/niri/config.kdl" = {
      generator = config.lib.generators.toNiriconf;
      value =
        {
          # Include wallust-generated border colors (live-reloads on wallpaper change)
          include._args = ["${config.user.homeDirectory}/.cache/wallust/niri-borders.kdl"];

          prefer-no-csd = {};

          cursor = {
            xcursor-theme = config.user.ui.cursor.package.xcursorThemeName;
            xcursor-size = config.user.appearance.xcursorSize;
          };

          screenshot-path = null;

          spawn-at-startup =
            [
              ["${pkgs.xwayland-satellite}/bin/xwayland-satellite"]
              ["sh" "-c" "swaybg -i $(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1) -m fill"]
            ]
            ++ lib.optional config.user.ui.vicinae.enable ["${pkgs.vicinae}/bin/vicinae" "server"]
            ++ lib.optional (config.user.ui.gpuishell.enable or false) ["${pkgs.gpuishell}/bin/gpuishell"]
            ++ lib.optional (config.user.ui.ags.bar-overlay.enable or false) ["${config.user.ui.ags.package}/bin/ags" "run" "/home/${config.user.name}/.config/ags/bar-overlay.tsx"]
            ++ lib.optional (config.user.ui.nur.enable or false) ["${config.user.ui.nur.package}/bin/nur"]
            ++ lib.optional (config.user.programs.handy.enable or false) ["handy"];

          hotkey-overlay = {};

          blur = {
            passes = 3;
            offset = 3;
            noise = 0.04;
          };

          window-rule = {
            match._props.app-id = "^launcher$";
            default-column-width.fixed = 800;
            default-window-height.fixed = 600;
          };
        }
        // {
          _extraConfig =
            ''
              window-rule {
                  background-effect {
                      blur true
                  }

                  popups {
                      background-effect {
                          blur true
                      }
                  }
              }

              layer-rule {
                  background-effect {
                      blur true
                  }

                  popups {
                      background-effect {
                          blur true
                      }
                  }
              }

              recent-windows {
                  off
              }

              gestures {
                  hot-corners {
                      off
                  }
              }
            ''
            + lib.optionalString (config.user.ui.niri.extraConfig != "") "\n${config.user.ui.niri.extraConfig}";
        };
    };
  };
}
