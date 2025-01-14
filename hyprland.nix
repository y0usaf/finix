#===============================================================================
#
#                     Hyprland Configuration
#
# Description:
#     Configuration file for the Hyprland Wayland compositor. Manages:
#     - Monitor setup and display configuration
#     - Window management and layout settings
#     - Keybindings and shortcuts
#     - Startup applications and services
#     - Visual appearance and animations
#
# Author: y0usaf
# Last Modified: 2025
#
#===============================================================================
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

  wayland.windowManager.hyprland = {
    enable = true;
    systemd = {
      enable = true;
      variables = ["--all"];
    };
    xwayland.enable = true;

    # Put monitor config in extraConfig to ensure it loads first
    extraConfig = ''
      # Monitor Configuration
      monitor=DP-4,5120x1440@239.76,0x0,1
      monitor=HDMI-A-2,5120x1440@239.76,0x0,1
    '';

    settings = {
      # General Settings
      general = {
        gaps_in = 10;
        gaps_out = 5;
        border_size = 1;
        "col.active_border" = "rgba($active_colour)";
        "col.inactive_border" = "rgba($inactive_colour)";
        layout = "hy3";
      };

      # Decoration Settings
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

      # Animation Settings
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

      # Input Settings
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = -1.0;
        force_no_accel = true;
        mouse_refocus = false;
      };

      # Misc Settings
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      # Debug Settings
      debug = {
        disable_logs = false;
      };

      # Variables
      "$mod" = "SUPER";
      "$mod2" = "ALT";
      "$term" = globals.defaultTerminal;
      "$filemanager" = globals.defaultFileManager;
      "$browser" = globals.defaultBrowser;
      "$discord" = globals.defaultDiscord;
      "$launcher" = globals.defaultLauncher;
      "$active_colour" = "ffffffff";
      "$transparent" = "00000000";
      "$inactive_colour" = "333333ff";
      "$ide" = globals.defaultIde;
      "$obs" = "obs";

      # Window Rules
      windowrulev2 = [
        "float, center, size 300 600, class:^(launcher)"
        "float, mouse, size 300 300, title:^(Smile)"
        "float, center, class:^(hyprland-share-picker)"
      ];

      # Layer Rules
      layerrule = [
        "blur, notifications"
        "blur, fabric"
      ];

      # Keybinds
      bind = lib.lists.flatten [
        # Basic window manager controls
        "$mod, W, exec, ~/.config/fabric/toggle_workspaces.sh"
        "$mod, D, exec, $term"
        "$mod, E, exec, $filemanager"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, R, exec, $launcher"
        "$mod, O, exec, $notepad"
        "$mod, F, fullscreen"
        "$mod, G, exec, grim -g \"$(slurp -d)\" - | wl-copy -t image/png"
        "$mod SHIFT, G, exec, grim - | wl-copy -t image/png"
        "$mod2, TAB, layoutmsg, swapnext"
        "$mod, GRAVE, exec, hyprpicker | wl-copy"
        "$mod, TAB, layoutmsg, orientationnext"
        "$mod, space, togglefloating"
        "$mod, P, pseudo"
        "$mod SHIFT, S, swapactiveworkspaces, DP-4 HDMI-A-2"
        "$mod, S, movecurrentworkspacetomonitor, +1"

        # Monitor controls
        "$mod2, 6, exec, hyprctl keyword monitor \"DP-4,5120x1440@239.76,0x0,1\" && hyprctl keyword monitor \"HDMI-A-2,5120x1440@239.76,0x1440,1\""
        "$mod2, 7, exec, hyprctl keyword monitor \"DP-4,disable\""

        # Application launchers
        "$mod2, 1, exec, $ide"
        "$mod2, 2, exec, $browser"
        "$mod2, 3, exec, $discord"
        "$mod2, 4, exec, $element"
        "$mod2, 5, exec, $obs"

        # Focus and window movement
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

        # Workspace switching
        (lib.lists.forEach (lib.range 1 9) (
          i: let
            num = toString i;
          in [
            "$mod, ${num}, workspace, ${toString i}"
            "$mod SHIFT, ${num}, movetoworkspacesilent, ${toString i}"
          ]
        ))

        # Media controls
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +10%"
        ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -10%"

        # System controls
        "Ctrl$mod2,Delete, exec, gnome-system-monitor"
        "$mod Shift, M, exec, shutdown now"
        "Ctrl$mod2Shift, M, exec, reboot"
        "Ctrl,Period,exec,smile"

        # Special commands
        "$mod SHIFT, C, exec, killall mpvpaper & exec swaybg -o DP-4 -i `find $WALLPAPER_DIR -type f | shuf -n 1` -m fill & exec swaybg -o HDMI-A-2 -i `find $WALLPAPER_DIR -type f | shuf -n 1` -m fill & exec hyprctl reload"
      ];

      # Mouse binds
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Startup commands
      exec-once = [
        "syncthing --no-browser"
        "exec --no-startup-id /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
        "hyprctl reload"
        "dbus-update-activation-environment --systemd HYPRLAND_INSTANCE_SIGNATURE"
      exec = [
        "udiskie"
      ];
    };
  };
}
