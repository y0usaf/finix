{
  config,
  lib,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.ui.hyprland.enable {
    bayt.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkAfter (genLib.toHyprconf {
        attrs = {
          "exec-once" = lib.optionals (config.user.ui.quickshell.enable or false) [
            "exec quickshell"
          ];
          bind = lib.optionals (config.user.ui.quickshell.enable or false) [
            "$mod2, TAB, exec, quickshell ipc call workspaces toggle"
          ];
        };
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
