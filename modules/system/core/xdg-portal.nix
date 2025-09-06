{pkgs, ...}: {
  config = {
    xdg.portal = {
      enable = true;
      config = {
        common = {
          default = ["gtk"];
        };
        niri = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
        };
        hyprland = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
        };
      };
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        xdg-desktop-portal-hyprland
      ];
    };
  };
}
