{
  config,
  lib,
  ...
}: let
  agsEnabled = config.home.ui.ags.enable or false;
in {
  "exec-once" = lib.optionals agsEnabled [
    "exec ags run"
  ];
  bind = lib.optionals agsEnabled [
    "$mod, W, exec, ags request showStats"
    "$mod2, TAB, exec, ags request toggleWorkspaces"
  ];
  bindr = lib.optionals agsEnabled [
    "$mod, W, exec, ags request hideStats"
  ];
}
