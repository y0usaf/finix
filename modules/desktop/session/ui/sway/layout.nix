{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.sway.enable {
    bayt.users."${config.user.name}".files.".config/sway/config".text = lib.mkAfter ''
      default_border pixel 1
      default_floating_border pixel 1
      hide_edge_borders none

      gaps inner 10
      gaps outer 0
      smart_gaps off

      workspace_layout tabbed
    '';
  };
}
