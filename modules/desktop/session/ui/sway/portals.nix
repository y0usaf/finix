{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.sway.enable {
    systemd.user.targets.sway-session.wants = [
      "xdg-desktop-portal.service"
      "xdg-desktop-portal-gtk.service"
      "xdg-desktop-portal-wlr.service"
    ];
  };
}
