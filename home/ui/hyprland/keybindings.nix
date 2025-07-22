{
  lib,
  defaults,
  cfg,
  ...
}: {
  "$mod" = "SUPER";
  "$mod2" = "ALT";
  "$term" = defaults.terminal;
  "$filemanager" = defaults.fileManager;
  "$browser" = defaults.browser;
  "$discord" = defaults.discord;
  "$launcher" = defaults.launcher;
  "$ide" = defaults.ide;
  "$notepad" = "${defaults.terminal} -e ${defaults.editor}";
  "$obs" = "obs";
  bind = lib.lists.flatten [
    (lib.optional cfg.group.enable "$mod CTRL, G, togglegroup")
    (lib.optional cfg.group.enable "$mod CTRL SHIFT, G, lockgroups, toggle")
    (lib.optional cfg.group.enable "$mod CTRL, J, changegroupactive, b")
    (lib.optional cfg.group.enable "$mod CTRL, K, changegroupactive, f")
    (lib.optional cfg.group.enable "$mod CTRL SHIFT, J, moveintogroup, b")
    (lib.optional cfg.group.enable "$mod CTRL SHIFT, K, moveintogroup, f")
    (lib.optional cfg.group.enable "$mod CTRL, H, moveoutofgroup")
    [
      "$mod, Q, killactive"
      "$mod, M, exit"
      "$mod, F, fullscreen"
      "$mod, TAB, layoutmsg, orientationnext"
      "$mod, space, togglefloating"
      "$mod, P, pseudo"
    ]
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
    [
      "$mod SHIFT, S, swapactiveworkspaces, DP-4 HDMI-A-2"
      "$mod, S, movecurrentworkspacetomonitor, +1"
    ]
    (lib.lists.forEach ["w" "a" "s" "d"] (key: let
      direction =
        {
          "w" = "u";
          "a" = "l";
          "s" = "d";
          "d" = "r";
        }
        .${
          key
        };
    in [
      "$mod2, ${key}, movefocus, ${direction}"
      "$mod2 SHIFT, ${key}, movewindow, ${direction}"
    ]))
    (lib.lists.forEach (lib.range 1 9) (i: let
      num = toString i;
    in [
      "$mod, ${num}, workspace, ${num}"
      "$mod SHIFT, ${num}, movetoworkspacesilent, ${num}"
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
      "$mod SHIFT, C, exec, killall swaybg; for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do wall=$(find /home/y0usaf/DCIM/Wallpapers/32_9 -type f | shuf -n 1); swaybg -o $monitor -i $wall -m fill & done"
    ]
  ];
  bindm = [
    "$mod, mouse:272, movewindow"
    "$mod, mouse:273, resizewindow"
  ];
}
