{
  config,
  lib,
  ...
}: let
  inherit (config.user) ui;
in {
  config = lib.mkIf ui.hyprland.enable {
    manzil.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
      text = lib.mkAfter (lib.optionalString (ui.quickshell.enable or false) ''
        exec-once = exec quickshell
        bind = $mod2, TAB, exec, quickshell ipc call workspaces toggle
      '');
    };
  };
}
