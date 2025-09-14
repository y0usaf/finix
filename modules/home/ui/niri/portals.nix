{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.niri;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xdg-desktop-portal
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    usr = {
      files.".config/xdg-desktop-portal/niri-portals.conf" = {
        generator = lib.generators.toINI {};
        value = {
          preferred = {
            default = "gtk;gnome";
            "org.freedesktop.impl.portal.ScreenCast" = "gnome";
          };
        };
      };
    };
  };
}
