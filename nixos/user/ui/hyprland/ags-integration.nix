{
  config,
  lib,
  genLib,
  ...
}: let
  agsEnabled = config.user.ui.ags.enable or false;

  agsConfig = {
    "exec-once" =
      lib.optionals agsEnabled [
        "exec ags run ~/.config/ags/bar-overlay.tsx"
      ]
      ++ [
        "for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do wall=$(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1); swaybg -o $monitor -i $wall -m fill & done"
      ];
    bind = lib.optionals agsEnabled [
      "$mod, W, exec, ags request showStats"
      "$mod2, TAB, exec, ags request toggleWorkspaces"
    ];
    bindr = lib.optionals agsEnabled [
      "$mod, W, exec, ags request hideStats"
    ];
  };
in {
  config = lib.mkIf config.user.ui.hyprland.enable {
    usr.files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkAfter (genLib.toHyprconf {
        attrs = agsConfig;
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
