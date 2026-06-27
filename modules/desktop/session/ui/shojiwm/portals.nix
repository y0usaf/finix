{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.user.ui.shojiwm.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
      config = {
        shojiwm = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["shojiwm"];
        };
      };
    };
  };
}
