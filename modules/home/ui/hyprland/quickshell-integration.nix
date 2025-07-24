{
  config,
  lib,
  ...
}: let
  quickshellEnabled = config.home.ui.quickshell.enable or false;
in {
  "exec-once" = lib.optionals quickshellEnabled [
    "exec quickshell"
  ];
  bind = lib.optionals quickshellEnabled [
    "$mod2, TAB, exec, quickshell ipc call workspaces toggle"
  ];
}
