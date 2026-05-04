{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.hyprland.enable {
    manzil.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
      text = lib.mkAfter (config.lib.generators.toHyprconf {
        attrs = {
          bind = lib.lists.flatten [
            [
              "$mod CTRL, G, togglegroup"
              "$mod CTRL, L, lockactivegroup, toggle"
              "$mod CTRL SHIFT, G, lockgroups, toggle"
              "$mod CTRL, J, changegroupactive, b"
              "$mod CTRL, K, changegroupactive, f"
              "$mod CTRL, H, moveoutofgroup"
              "$mod, comma, moveintogroup, l"
              "$mod, period, moveoutofgroup"
              "$mod, bracketleft, movewindoworgroup, l"
              "$mod, bracketright, movewindoworgroup, r"
            ]
            [
              "$mod, Q, killactive"
              "$mod, M, exit"
              "$mod, P, pseudo"
            ]
            [
              "$mod, F, fullscreen, 1"
              "$mod SHIFT, F, fullscreen"
              "$mod2, F, fullscreenstate, 0 2 toggle"
              "$mod, TAB, cyclenext"
              "$mod, space, layoutmsg, fit active"
              "$mod2, space, togglefloating"
              "$mod SHIFT, E, exit"
            ]
            [
              "$mod, T, exec, $term"
              "$mod, E, exec, $filemanager"
              "$mod2, R, exec, $launcher"
              "$mod, O, exec, $notepad"
              "$mod2 SHIFT, O, exec, $notepad"
              "$mod, R, layoutmsg, colresize +conf"
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
            [
              "$mod, h, layoutmsg, focus l"
              "$mod, j, changegroupactive, b"
              "$mod, k, changegroupactive, f"
              "$mod, l, layoutmsg, focus r"
              "$mod, left, layoutmsg, focus l"
              "$mod, down, changegroupactive, b"
              "$mod, up, changegroupactive, f"
              "$mod, right, layoutmsg, focus r"
              "$mod SHIFT, h, layoutmsg, swapcol l"
              "$mod SHIFT, j, movegroupwindow, b"
              "$mod SHIFT, k, movegroupwindow, f"
              "$mod SHIFT, l, layoutmsg, swapcol r"
              "$mod SHIFT, left, layoutmsg, swapcol l"
              "$mod SHIFT, down, movegroupwindow, b"
              "$mod SHIFT, up, movegroupwindow, f"
              "$mod SHIFT, right, layoutmsg, swapcol r"
            ]
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
