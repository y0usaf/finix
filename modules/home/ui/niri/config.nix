{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.ui.niri;
  inherit (config.home.core) defaults;
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
          text = ''
            input {
                keyboard {
                    xkb {
                        layout "us"
                    }
                }

                touchpad {
                    tap
                    dwt
                    natural-scroll
                    accel-speed 0.2
                }

                mouse {
                    accel-speed 0.2
                }

                // Set Alt as primary mod key
                mod-key "Alt"
            }

            output "DP-4" {
                mode "5120x1440@239.761"
                position x=0 y=0
            }

            output "HDMI-A-2" {
                mode "1920x1080@60.000"
                position x=5120 y=0
            }

            layout {
                gaps 16
                center-focused-column "never"
                preset-column-widths {
                    proportion 0.33333
                    proportion 0.5
                    proportion 0.66667
                }
                default-column-width { proportion 0.5; }
            }

            prefer-no-csd

            hotkey-overlay {
                // Removed skip-at-startup so it shows on startup
            }

            animations {
                slowdown 1.0
                horizontal-view-movement {
                    spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
                }
                window-movement {
                    spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
                }
                window-open {
                    duration-ms 150
                    curve "ease-out-expo"
                }
                window-close {
                    duration-ms 150
                    curve "ease-out-expo"
                }
                config-notification-open-close {
                    spring damping-ratio=0.6 stiffness=1000 epsilon=0.001
                }
            }

            window-rule {
                match app-id="firefox"
                default-column-width { proportion 0.75; }
            }

            window-rule {
                match app-id="foot"
                opacity 1.0
            }

            window-rule {
                match app-id="launcher"
                open-floating
                default-column-width { fixed 800; }
            }

            binds {
                // Now Mod = Alt, so these are Alt-based default Niri bindings
                Mod+Shift+Slash { show-hotkey-overlay; }

                // Terminal and launcher (now Alt+T, Alt+D)
                Mod+T { spawn "${defaults.terminal}"; }
                Mod+D { spawn "${defaults.launcher}"; }

                // Window management (now Alt-based)
                Mod+Q { close-window; }
                Mod+Shift+F { fullscreen-window; }
                Mod+F { maximize-column; }
                Mod+Space { center-column; }

                // Focus movement (now Alt+HJKL as desired)
                Mod+Left { focus-column-left; }
                Mod+Right { focus-column-right; }
                Mod+Up { focus-window-up; }
                Mod+Down { focus-window-down; }
                Mod+H { focus-column-left; }
                Mod+L { focus-column-right; }
                Mod+J { focus-window-down; }
                Mod+K { focus-window-up; }

                // Window movement (Alt+Ctrl)
                Mod+Ctrl+Left { move-column-left; }
                Mod+Ctrl+Right { move-column-right; }
                Mod+Ctrl+Up { move-window-up; }
                Mod+Ctrl+Down { move-window-down; }
                Mod+Ctrl+H { move-column-left; }
                Mod+Ctrl+L { move-column-right; }
                Mod+Ctrl+J { move-window-down; }
                Mod+Ctrl+K { move-window-up; }

                // Workspace switching (Alt+numbers)
                Mod+Page_Up { focus-workspace-up; }
                Mod+Page_Down { focus-workspace-down; }
                Mod+U { focus-workspace-up; }
                Mod+I { focus-workspace-down; }
                Mod+1 { focus-workspace 1; }
                Mod+2 { focus-workspace 2; }
                Mod+3 { focus-workspace 3; }
                Mod+4 { focus-workspace 4; }
                Mod+5 { focus-workspace 5; }
                Mod+6 { focus-workspace 6; }
                Mod+7 { focus-workspace 7; }
                Mod+8 { focus-workspace 8; }
                Mod+9 { focus-workspace 9; }

                // Move to workspace (Alt+Ctrl+numbers)
                Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
                Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
                Mod+Ctrl+U { move-column-to-workspace-up; }
                Mod+Ctrl+I { move-column-to-workspace-down; }
                Mod+Ctrl+1 { move-column-to-workspace 1; }
                Mod+Ctrl+2 { move-column-to-workspace 2; }
                Mod+Ctrl+3 { move-column-to-workspace 3; }
                Mod+Ctrl+4 { move-column-to-workspace 4; }
                Mod+Ctrl+5 { move-column-to-workspace 5; }
                Mod+Ctrl+6 { move-column-to-workspace 6; }
                Mod+Ctrl+7 { move-column-to-workspace 7; }
                Mod+Ctrl+8 { move-column-to-workspace 8; }
                Mod+Ctrl+9 { move-column-to-workspace 9; }

                // Layout controls (Alt+R, Alt+comma, etc.)
                Mod+R { switch-preset-column-width; }
                Mod+Shift+R { switch-preset-window-height; }
                Mod+Comma { consume-window-into-column; }
                Mod+Period { expel-window-from-column; }
                Mod+BracketLeft { consume-or-expel-window-left; }
                Mod+BracketRight { consume-or-expel-window-right; }

                // Screenshots
                Print { spawn "grim" "-g" "$(slurp -d)" "-" "|" "wl-copy" "-t" "image/png"; }
                Ctrl+Print { spawn "grim" "-" "|" "wl-copy" "-t" "image/png"; }
                Shift+Print { spawn "grim" "-g" "$(slurp -w)" "-" "|" "wl-copy" "-t" "image/png"; }

                // System (Alt+Shift+E to quit, Alt+O for overview)
                Mod+Shift+E { quit; }
                Mod+O { toggle-overview; }

                // Custom app bindings using Super key (to avoid conflicts)
                Super+1 { spawn "${defaults.ide}"; }
                Super+2 { spawn "${defaults.browser}"; }
                Super+3 { spawn "vesktop"; }
                Super+4 { spawn "steam"; }
                Super+5 { spawn "obs"; }

                // Additional useful bindings
                Mod+E { spawn "${defaults.fileManager}"; }
                Mod+Shift+O { spawn "${defaults.terminal}" "-e" "${defaults.editor}"; }
            }
            spawn-at-startup "${pkgs.xwayland-satellite}/bin/xwayland-satellite"

            environment {
                DISPLAY ":0"
            }
          '';
        };
      };
    };
  };
}
