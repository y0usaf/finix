{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.niri;
  generators = import ../../../../lib/generators {inherit lib;};
in {
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];

      files.".config/xdg-desktop-portal/niri-portals.conf" = {
        generator = generators.toINI {};
        value = {
          preferred = {
            default = "gtk;gnome";
            "org.freedesktop.impl.portal.ScreenCast" = "gnome";
          };
        };
      };

      files.".config/systemd/user/xdg-desktop-portal-gtk.service.d/ordering.conf" = {
        generator = generators.toINI {};
        value = {
          Unit = {
            After = "xdg-desktop-portal.service";
            Wants = "xdg-desktop-portal.service";
          };
        };
      };

      files.".config/systemd/user/graphical-session.target.wants/xdg-desktop-portal-gtk.service".text = "";

      files.".config/systemd/user/xdg-desktop-portal-gnome.service.d/ordering.conf" = {
        generator = generators.toINI {};
        value = {
          Unit = {
            After = "xdg-desktop-portal-gtk.service";
            Wants = "xdg-desktop-portal-gtk.service";
          };
        };
      };

      files.".config/systemd/user/graphical-session.target.wants/xdg-desktop-portal-gnome.service".text = "";
    };
  };
}
