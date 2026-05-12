{
  config,
  lib,
  ...
}: let
  quickshellEnabled = config.user.ui.quickshell.enable or false;
in {
  config = lib.mkIf config.user.ui.hyprland.enable {
    manzil.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
      text = lib.mkAfter (lib.optionalString quickshellEnabled ''
        exec-once = exec quickshell
        bind = $mod2, TAB, exec, quickshell ipc call workspaces toggle
      '');
    };
  };
}
