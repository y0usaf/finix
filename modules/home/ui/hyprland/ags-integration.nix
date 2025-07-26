{
  config,
  lib,
  ...
}: let
  agsEnabled = config.home.ui.ags.enable or false;
in {
  "exec-once" = lib.optionals agsEnabled [
    "exec ags run"
  ] ++ [
    # Initial wallpaper setup
    "for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do wall=$(find ${config.home.directories.wallpapers.static.path} -type f | shuf -n 1); swaybg -o $monitor -i $wall -m fill & done"
  ];
  bind = lib.optionals agsEnabled [
    "$mod, W, exec, ags request showStats"
    "$mod2, TAB, exec, ags request toggleWorkspaces"
  ];
  bindr = lib.optionals agsEnabled [
    "$mod, W, exec, ags request hideStats"
  ];
}
