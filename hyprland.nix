#──────────────────────── 🪟 HYPRLAND CONFIG ────────────────────────#
# 🎮 Core settings and plugins | Home-manager module                 #
#──────────────────────────────────────────────────────────────────────#
{
  config,
  pkgs,
  lib,
  inputs,
  globals,
  ...
}: {
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];

  options.gui.hypr.xdph.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enables xdph and its configs.";
  };

  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      systemd.variables = ["--all"];
      xwayland.enable = true;
      plugins = [
        inputs.hy3.packages.${pkgs.system}.hy3
      ];

      settings = {
        # Display Configuration
        monitor = [
          "DP-4,5120x1440@239.76,0x0,1"
          "DP-2,5120x1440@239.76,0x0,1"
          "HDMI-A-2,5120x1440@239.76,0x0,1"
        ];

        # Color Definitions
        "$active_colour" = "ffffffff";
        "$transparent" = "00000000";
        "$inactive_colour" = "333333ff";

        # Core Variables
        "$mod" = "SUPER";
        "$mod2" = "ALT";
        "$term" = globals.defaultTerminal;
        "$filemanager" = globals.defaultFileManager;
        "$browser" = globals.defaultBrowser;
        "$discord" = globals.defaultDiscord;
        "$launcher" = globals.defaultLauncher;
        "$ide" = globals.defaultIde;
        "$obs" = "obs";

        # Core Settings
        general = {
          gaps_in = 10;
          gaps_out = 5;
          border_size = 1;
          "col.active_border" = "rgba($active_colour)";
          "col.inactive_border" = "rgba($inactive_colour)";
          layout = "hy3";
        };

        # Input Settings
        input = {
          kb_layout = "us";
          follow_mouse = 1;
          sensitivity = -1.0;
          force_no_accel = true;
          mouse_refocus = false;
        };

        #── ⚙️ Misc Settings ──────────────────────#
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };

        debug.disable_logs = false;

        #── 🎨 Visual Settings ─────────────────────#
        decoration = {
          rounding = 0;
          blur = {
            enabled = true;
            size = 5;
            passes = 3;
            new_optimizations = true;
            ignore_opacity = false;
            noise = 0;
            brightness = 1;
            popups = true;
          };
        };

        animations = {
          enabled = 0;
          bezier = [
            "in-out,.65,-0.01,0,.95"
            "woa,0,0,0,1"
          ];
          animation = [
            "windows,1,2,woa,popin"
            "border,1,10,default"
            "fade,1,10,default"
            "workspaces,1,5,in-out,slide"
          ];
        };

        #── 🪟 Window Rules ───────────────────────#
        windowrulev2 = [
          "float, center, size 300 600, class:^(launcher)"
          "float, mouse, size 300 300, title:^(Smile)"
          "float, center, class:^(hyprland-share-picker)"
          "float, class:^(ags)$ title:^(system-stats)$"
          "center, class:^(ags)$ title:^(system-stats)$"
        ];

        layerrule = [
          "blur, notifications"
          "blur, fabric"
        ];

        #── ⌨️ Key Bindings ───────────────────────#
        bind = lib.lists.flatten [
          #── 🪟 Window Management ────────────────#
          [
            "$mod, Q, killactive"
            "$mod, M, exit"
            "$mod, F, fullscreen"
            "$mod2, TAB, layoutmsg, swapnext"
            "$mod, TAB, layoutmsg, orientationnext"
            "$mod, space, togglefloating"
            "$mod, P, pseudo"
            "$mod, W, exec, ags -r 'showStats()'"
          ]

          #── 🔔 Monitor Controls ────────────────#
          [
            "$mod SHIFT, S, swapactiveworkspaces, DP-4 HDMI-A-2"
            "$mod, S, movecurrentworkspacetomonitor, +1"
          ]

          #── 🚀 Application Shortcuts ───────────#
          [
            "$mod, D, exec, $term"
            "$mod, E, exec, $filemanager"
            "$mod, R, exec, $launcher"
            "$mod, O, exec, $notepad"
            "$mod2, 1, exec, $ide"
            "$mod2, 2, exec, $browser"
            "$mod2, 3, exec, $discord"
            "$mod2, 4, exec, steam"
            "$mod2, 5, exec, $obs"
          ]

          #── 📸 Screenshot & Color Picker ───────#
          [
            "$mod, G, exec, grim -g \"$(slurp -d)\" - | wl-copy -t image/png"
            "$mod SHIFT, G, exec, grim - | wl-copy -t image/png"
            "$mod, GRAVE, exec, hyprpicker | wl-copy"
          ]

          #── 🔍 Focus & Window Movement ─────────#
          (lib.lists.forEach ["w" "a" "s" "d"] (key: let
            direction =
              {
                "w" = "u";
                "a" = "l";
                "s" = "d";
                "d" = "r";
              }
              .${key};
          in [
            "$mod2, ${key}, movefocus, ${direction}"
            "$mod2 SHIFT, ${key}, movewindow, ${direction}"
          ]))

          #── 🏢 Workspace Management ───────────#
          (lib.lists.forEach (lib.range 1 9) (i: let
            num = toString i;
          in [
            "$mod, ${num}, workspace, ${toString i}"
            "$mod SHIFT, ${num}, movetoworkspacesilent, ${toString i}"
          ]))

          #── 🎵 Media Controls ─────────────────#
          [
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", XF86AudioPrev, exec, playerctl previous"
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +10%"
            ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -10%"
          ]

          #── 💻 System Controls ────────────────#
          [
            "Ctrl$mod2,Delete, exec, gnome-system-monitor"
            "$mod Shift, M, exec, shutdown now"
            "Ctrl$mod2Shift, M, exec, reboot"
            "Ctrl,Period,exec,smile"
          ]

          #── ⚡ Special Commands ───────────────#
          [
            "$mod SHIFT, C, exec, killall mpvpaper & exec swaybg -o DP-4 -i `find $WALLPAPER_DIR -type f | shuf -n 1` -m fill & exec swaybg -o HDMI-A-2 -i `find $WALLPAPER_DIR -type f | shuf -n 1` -m fill & exec hyprctl reload"
          ]
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        bindr = "$mod, W, exec, ags -r 'hideStats()'";
      };
    };

    # XDPH configuration moved inside main config attribute
    home.file = lib.mkIf config.gui.hypr.xdph.enable {
      "${config.xdg.configHome}/hypr/xdph.conf".text = ''
        screencopy {
          max_fps = 240
          allow_token_by_default = true
        }
      '';
    };
  };
}
