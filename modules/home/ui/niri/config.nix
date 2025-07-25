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
                skip-at-startup
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

            binds {
                // Window management (similar to Hyprland)
                Mod+Q { close-window; }
                Mod+M { quit; }
                Mod+F { fullscreen-window; }
                Mod+Space { toggle-window-floating; }
                
                // Applications (matching Hyprland bindings)
                Mod+D { spawn "${defaults.terminal}"; }
                Mod+E { spawn "${defaults.fileManager}"; }
                Mod+R { spawn "${defaults.launcher}"; }
                Mod+O { spawn "${defaults.terminal}" "-e" "${defaults.editor}"; }
                Alt+1 { spawn "${defaults.ide}"; }
                Alt+2 { spawn "${defaults.browser}"; }
                Alt+3 { spawn "${defaults.discord}"; }
                Alt+4 { spawn "steam"; }
                Alt+5 { spawn "obs"; }
                
                // Focus movement (vim-like)
                Alt+H { focus-column-left; }
                Alt+L { focus-column-right; }
                Alt+J { focus-window-down; }
                Alt+K { focus-window-up; }
                
                // Window movement
                Alt+Shift+H { move-column-left; }
                Alt+Shift+L { move-column-right; }
                Alt+Shift+J { move-window-down; }
                Alt+Shift+K { move-window-up; }
                
                // Workspace switching
                Mod+1 { focus-workspace 1; }
                Mod+2 { focus-workspace 2; }
                Mod+3 { focus-workspace 3; }
                Mod+4 { focus-workspace 4; }
                Mod+5 { focus-workspace 5; }
                Mod+6 { focus-workspace 6; }
                Mod+7 { focus-workspace 7; }
                Mod+8 { focus-workspace 8; }
                Mod+9 { focus-workspace 9; }
                
                // Move to workspace
                Mod+Shift+1 { move-column-to-workspace 1; }
                Mod+Shift+2 { move-column-to-workspace 2; }
                Mod+Shift+3 { move-column-to-workspace 3; }
                Mod+Shift+4 { move-column-to-workspace 4; }
                Mod+Shift+5 { move-column-to-workspace 5; }
                Mod+Shift+6 { move-column-to-workspace 6; }
                Mod+Shift+7 { move-column-to-workspace 7; }
                Mod+Shift+8 { move-column-to-workspace 8; }
                Mod+Shift+9 { move-column-to-workspace 9; }
                
                // Monitor management
                Mod+S { move-workspace-to-monitor-right; }
                Mod+Shift+S { move-workspace-to-monitor-left; }
                
                // Screenshots (matching Hyprland)
                Mod+G { spawn "grim" "-g" "$(slurp -d)" "-" "|" "wl-copy" "-t" "image/png"; }
                Mod+Shift+G { spawn "grim" "-" "|" "wl-copy" "-t" "image/png"; }
                
                // System controls
                Ctrl+Alt+Delete { spawn "gnome-system-monitor"; }
                Mod+Shift+M { spawn "shutdown" "now"; }
                Ctrl+Alt+Shift+M { spawn "reboot"; }
                
                // Column width adjustment
                Mod+Minus { set-column-width "-10%"; }
                Mod+Equal { set-column-width "+10%"; }
                Mod+Shift+Minus { set-window-height "-10%"; }
                Mod+Shift+Equal { set-window-height "+10%"; }
                
                // Reset column width
                Mod+0 { reset-window-height; }
                
                // Switch preset column widths
                Mod+Shift+R { switch-preset-column-width; }
                
                // Consume or expel window into/from column
                Mod+Comma { consume-window-into-column; }
                Mod+Period { expel-window-from-column; }
                
                // Center column
                Mod+C { center-column; }
                
                // Focus monitor
                Mod+Shift+Left { focus-monitor-left; }
                Mod+Shift+Right { focus-monitor-right; }
                Mod+Shift+Up { focus-monitor-up; }
                Mod+Shift+Down { focus-monitor-down; }
                
                // Move column to monitor
                Mod+Ctrl+Left { move-column-to-monitor-left; }
                Mod+Ctrl+Right { move-column-to-monitor-right; }
                Mod+Ctrl+Up { move-column-to-monitor-up; }
                Mod+Ctrl+Down { move-column-to-monitor-down; }
                
                // Show hotkey overlay
                Mod+Shift+Slash { show-hotkey-overlay; }
            }
          '';
        };
      };
    };
  };
}