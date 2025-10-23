{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-gnome
      ];
      config = {
        niri = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
        };
      };
    };
  };
}
