{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    bayt.users."${config.user.name}" = {
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

    systemd.user.tmpfiles.rules = [
      "d %t/systemd/user/xdg-desktop-portal-gnome.service.d 0755 - - - -"
      "d %t/systemd/user/xdg-desktop-portal-gtk.service.d 0755 - - - -"
      "d %t/systemd/user/xdg-desktop-portal.service.d 0755 - - - -"
      "L+ %t/systemd/user/xdg-desktop-portal-gnome.service.d/environment.conf - - - - ${pkgs.writeText "xdg-desktop-portal-gnome-environment.conf" ''
        [Service]
        PassEnvironment=WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      ''}"
      "L+ %t/systemd/user/xdg-desktop-portal-gnome.service.d/override.conf - - - - ${pkgs.writeText "xdg-desktop-portal-gnome-override.conf" ''
        [Service]
        Restart=always

        [Unit]
        After=xdg-desktop-portal-gtk.service
      ''}"
      "L+ %t/systemd/user/xdg-desktop-portal-gtk.service.d/override.conf - - - - ${pkgs.writeText "xdg-desktop-portal-gtk-override.conf" ''
        [Service]
        Restart=always

        [Unit]
        After=xdg-desktop-portal.service
        Wants=xdg-desktop-portal-gnome.service
      ''}"
      "L+ %t/systemd/user/xdg-desktop-portal.service.d/override.conf - - - - ${pkgs.writeText "xdg-desktop-portal-override.conf" ''
        [Service]
        Restart=always

        [Unit]
        Wants=xdg-desktop-portal-gtk.service
      ''}"
    ];

    systemd.user.targets.niri-session = {
      wants = [
        "xdg-desktop-portal.service"
        "xdg-desktop-portal-gtk.service"
        "xdg-desktop-portal-gnome.service"
      ];
    };
  };
}
