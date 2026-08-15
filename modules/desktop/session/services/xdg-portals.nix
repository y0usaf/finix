{
  config,
  lib,
  ...
}: {
  config = {
    manzil.users."${config.user.name}" = {
      files = {
        ".local/share/xdg-desktop-portal/portals/gnome.portal" = {
          generator = lib.generators.toINI {};
          value = {
            portal = {
              DBusName = "org.freedesktop.impl.portal.desktop.gnome";
              Interfaces = "org.freedesktop.impl.portal.ScreenCast;org.freedesktop.impl.portal.Screenshot;org.freedesktop.impl.portal.RemoteDesktop;";
              UseIn = "niri;gnome;";
            };
          };
        };

        ".local/share/xdg-desktop-portal/portals/gtk.portal" = {
          generator = lib.generators.toINI {};
          value = {
            portal = {
              DBusName = "org.freedesktop.impl.portal.desktop.gtk";
              Interfaces = "org.freedesktop.impl.portal.FileChooser;org.freedesktop.impl.portal.AppChooser;org.freedesktop.impl.portal.Print;org.freedesktop.impl.portal.Notification;";
              UseIn = "niri;gtk;";
            };
          };
        };
      };
    };
  };
}
