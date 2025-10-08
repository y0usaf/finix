{
  config,
  lib,
  genLib,
  ...
}: let
  quickshellEnabled = config.home.ui.quickshell.enable or false;

  quickshellConfig = {
    "exec-once" = lib.optionals quickshellEnabled [
      "exec quickshell"
    ];
    bind = lib.optionals quickshellEnabled [
      "$mod2, TAB, exec, quickshell ipc call workspaces toggle"
    ];
  };
in {
  config = lib.mkIf config.home.ui.hyprland.enable {
    usr.files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkAfter (genLib.toHyprconf {
        attrs = quickshellConfig;
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
