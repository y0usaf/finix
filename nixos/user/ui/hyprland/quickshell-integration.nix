{
  config,
  lib,
  genLib,
  ...
}: let
  quickshellConfig = {
    "exec-once" = lib.optionals (config.user.ui.quickshell.enable or false) [
      "exec quickshell"
    ];
    bind = lib.optionals (config.user.ui.quickshell.enable or false) [
      "$mod2, TAB, exec, quickshell ipc call workspaces toggle"
    ];
  };
in {
  config = lib.mkIf config.user.ui.hyprland.enable {
    usr.files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkAfter (genLib.toHyprconf {
        attrs = quickshellConfig;
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
