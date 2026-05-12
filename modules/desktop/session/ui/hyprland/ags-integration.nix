{
  config,
  lib,
  ...
}: let
  startupCommands =
    lib.optionals (config.user.ui.gpuishell.enable or false) [
      "gpuishell"
    ]
    ++ [
      "for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do wall=$(find ${config.user.paths.wallpapers.static.path} -type f | shuf -n 1); swaybg -o $monitor -i $wall -m fill & done"
    ];
in {
  config =
    lib.mkIf config.user.ui.hyprland.enable {
      manzil.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
        text = lib.mkAfter (lib.concatMapStringsSep "
" (cmd: "exec-once = ${cmd}") startupCommands);
      };
    };
}
