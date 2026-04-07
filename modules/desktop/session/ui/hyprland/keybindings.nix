{
  lib,
  config,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.ui.hyprland.enable {
    bayt.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
      text = lib.mkAfter (genLib.toHyprconf {
        attrs = {
          bind =
            lib.lists.flatten [
              (lib.optional config.user.ui.hyprland.group.enable "$mod CTRL, G, togglegroup")
              (lib.optional config.user.ui.hyprland.group.enable "$mod CTRL SHIFT, G, lockgroups, toggle")
              (lib.optional config.user.ui.hyprland.group.enable "$mod CTRL, J, changegroupactive, b")
              (lib.optional config.user.ui.hyprland.group.enable "$mod CTRL, K, changegroupactive, f")
              (lib.optional config.user.ui.hyprland.group.enable "$mod CTRL SHIFT, J, moveintogroup, b")
              (lib.optional config.user.ui.hyprland.group.enable "$mod CTRL SHIFT, K, moveintogroup, f")
              (lib.optional config.user.ui.hyprland.group.enable "$mod CTRL, H, moveoutofgroup")
              [
                "$mod, Q, killactive"
                "$mod, M, exit"
                "$mod, F, fullscreen"
                "$mod, TAB, layoutmsg, orientationnext"
                "$mod, space, togglefloating"
                "$mod, P, pseudo"
              ]
              [
                "$mod, T, exec, $term"
                "$mod, E, exec, $filemanager"
                "$mod, R, exec, $launcher"
                "$mod, O, exec, $notepad"
                "$mod, 1, exec, $ide"
                "$mod, 2, exec, $browser"
                "$mod, 3, exec, discord"
                "$mod, 4, exec, steam"
                "$mod, 5, exec, $obs"
              ]
              [
                "$mod SHIFT, S, swapactiveworkspaces, DP-4 HDMI-A-2"
                "$mod, S, movecurrentworkspacetomonitor, +1"
              ]
              (lib.lists.forEach ["h" "j" "k" "l"] (key: [
                    "$mod, ${key}, movefocus, ${
                      {
                        "k" = "u";
                        "h" = "l";
                        "j" = "d";
                        "l" = "r";
                      }
          ."${key}"
                    }"
                    "$mod SHIFT, ${key}, movewindow, ${
                      {
                        "k" = "u";
                        "h" = "l";
                        "j" = "d";
                        "l" = "r";
                      }
          ."${key}"
                    }"
                  ]))
              (lib.lists.forEach (lib.range 1 9) (i: [
                "$mod2, ${toString i}, workspace, ${toString i}"
                "$mod2 SHIFT, ${toString i}, movetoworkspacesilent, ${toString i}"
              ]))

              [
                "Ctrl$mod2,Delete, exec, gnome-system-monitor"
                "$mod Shift, M, exec, shutdown now"
                "Ctrl$mod2Shift, M, exec, reboot"
                "Ctrl,Period,exec,smile"
              ]
              [
                "$mod, G, exec, grim -g \"$(slurp -d)\" - | wl-copy -t image/png"
                "$mod SHIFT, G, exec, grim - | wl-copy -t image/png"
                "$mod, GRAVE, exec, hyprpicker | wl-copy"
              ]
              [
                "$mod SHIFT, C, exec, killall swaybg; for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do wall=$(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1); swaybg -o $monitor -i $wall -m fill & done"
              ]
            ];
          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];
        };
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
