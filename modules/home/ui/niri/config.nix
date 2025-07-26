{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.ui.niri;
  inherit (config.home.core) defaults;
  kdlGenerators = import ../../../../lib/generators/toKdl.nix lib;
  inherit (kdlGenerators) toKDL;
in {
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid = {
      packages = [
        pkgs.niri
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.jq
        pkgs.swaybg
      ];

      file.xdg_config = {
        "niri/config.kdl" = {
          text = toKDL {
            input = {
              keyboard.xkb.layout = "us";
              touchpad = {
                tap = true;
                dwt = true;
                natural-scroll = true;
                accel-speed = 0.2;
              };
              mouse.accel-speed = 0.2;
              mod-key = "Alt";
            };

            output = {
              "DP-4" = {
                mode = "5120x1440@239.761";
                position = { x = 0; y = 0; };
              };
              "HDMI-A-2" = {
                mode = "1920x1080@60.000";
                position = { x = 5120; y = 0; };
              };
            };

            layout = {
              gaps = 16;
              center-focused-column = "never";
              preset-column-widths = [
                { proportion = 0.33333; }
                { proportion = 0.5; }
                { proportion = 0.66667; }
              ];
              default-column-width.proportion = 0.5;
            };

            prefer-no-csd = true;

            hotkey-overlay = {};

            animations = {
              slowdown = 1.0;
              horizontal-view-movement = {
                spring = {
                  damping-ratio = 1.0;
                  stiffness = 800;
                  epsilon = 0.0001;
                };
              };
              window-movement = {
                spring = {
                  damping-ratio = 1.0;
                  stiffness = 800;
                  epsilon = 0.0001;
                };
              };
              window-open = {
                duration-ms = 150;
                curve = "ease-out-expo";
              };
              window-close = {
                duration-ms = 150;
                curve = "ease-out-expo";
              };
              config-notification-open-close = {
                spring = {
                  damping-ratio = 0.6;
                  stiffness = 1000;
                  epsilon = 0.001;
                };
              };
            };

            window-rule = [
              {
                match.app-id = "firefox";
                default-column-width.proportion = 0.75;
              }
              {
                match.app-id = "foot";
                opacity = 1.0;
              }
              {
                match.app-id = "launcher";
                open-floating = true;
              }
            ];

            binds = {
              "Mod+Shift+Slash".show-hotkey-overlay = true;

              "Mod+T".spawn = defaults.terminal;
              "Super+R".spawn = defaults.launcher;

              "Mod+Q".close-window = true;
              "Mod+Shift+F".fullscreen-window = true;
              "Mod+F".maximize-column = true;
              "Mod+Space".center-column = true;

              "Mod+Left".focus-column-left = true;
              "Mod+Right".focus-column-right = true;
              "Mod+Up".focus-window-up = true;
              "Mod+Down".focus-window-down = true;
              "Mod+H".focus-column-left = true;
              "Mod+L".focus-column-right = true;
              "Mod+J".focus-window-down = true;
              "Mod+K".focus-window-up = true;

              "Mod+Ctrl+Left".move-column-left = true;
              "Mod+Ctrl+Right".move-column-right = true;
              "Mod+Ctrl+Up".move-window-up = true;
              "Mod+Ctrl+Down".move-window-down = true;
              "Mod+Ctrl+H".move-column-left = true;
              "Mod+Ctrl+L".move-column-right = true;
              "Mod+Ctrl+J".move-window-down = true;
              "Mod+Ctrl+K".move-window-up = true;

              "Mod+Page_Up".focus-workspace-up = true;
              "Mod+Page_Down".focus-workspace-down = true;
              "Mod+U".focus-workspace-up = true;
              "Mod+I".focus-workspace-down = true;
              "Mod+1".focus-workspace = 1;
              "Mod+2".focus-workspace = 2;
              "Mod+3".focus-workspace = 3;
              "Mod+4".focus-workspace = 4;
              "Mod+5".focus-workspace = 5;
              "Mod+6".focus-workspace = 6;
              "Mod+7".focus-workspace = 7;
              "Mod+8".focus-workspace = 8;
              "Mod+9".focus-workspace = 9;

              "Mod+Ctrl+Page_Up".move-column-to-workspace-up = true;
              "Mod+Ctrl+Page_Down".move-column-to-workspace-down = true;
              "Mod+Ctrl+U".move-column-to-workspace-up = true;
              "Mod+Ctrl+I".move-column-to-workspace-down = true;
              "Mod+Ctrl+1".move-column-to-workspace = 1;
              "Mod+Ctrl+2".move-column-to-workspace = 2;
              "Mod+Ctrl+3".move-column-to-workspace = 3;
              "Mod+Ctrl+4".move-column-to-workspace = 4;
              "Mod+Ctrl+5".move-column-to-workspace = 5;
              "Mod+Ctrl+6".move-column-to-workspace = 6;
              "Mod+Ctrl+7".move-column-to-workspace = 7;
              "Mod+Ctrl+8".move-column-to-workspace = 8;
              "Mod+Ctrl+9".move-column-to-workspace = 9;

              "Mod+R".switch-preset-column-width = true;
              "Mod+Shift+R".switch-preset-window-height = true;
              "Mod+Comma".consume-window-into-column = true;
              "Mod+Period".expel-window-from-column = true;
              "Mod+BracketLeft".consume-or-expel-window-left = true;
              "Mod+BracketRight".consume-or-expel-window-right = true;

              "Print".spawn = ["grim" "-g" "$(slurp -d)" "-" "|" "wl-copy" "-t" "image/png"];
              "Ctrl+Print".spawn = ["grim" "-" "|" "wl-copy" "-t" "image/png"];
              "Shift+Print".spawn = ["grim" "-g" "$(slurp -w)" "-" "|" "wl-copy" "-t" "image/png"];

              "Mod+Shift+E".quit = true;
              "Mod+O".toggle-overview = true;

              "Super+1".spawn = defaults.ide;
              "Super+2".spawn = defaults.browser;
              "Super+3".spawn = "vesktop";
              "Super+4".spawn = "steam";
              "Super+5".spawn = "obs";

              "Mod+E".spawn = defaults.fileManager;
              "Mod+Shift+O".spawn = [defaults.terminal "-e" defaults.editor];
            };

            spawn-at-startup = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";

            environment = {
              DISPLAY = ":0";
            };
          };
        };
      };
    };
  };
}
