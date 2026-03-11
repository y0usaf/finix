{
  config,
  lib,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.ui.hyprland.enable {
    usr.files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkAfter (genLib.toHyprconf {
        attrs = {
          "exec-once" =
            lib.optionals (config.user.ui.gpuishell.enable or false) [
              "gpuishell"
            ]
            ++ [
              "for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do wall=$(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1); swaybg -o $monitor -i $wall -m fill & done"
            ];
        };
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
