{lib, ...}: {
  config = {
    usr = {
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

        ".config/systemd/user/xdg-desktop-portal-gnome.service.d/environment.conf" = {
          generator = lib.generators.toINI {};
          value = {
            Service = {
              PassEnvironment = "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";
            };
          };
        };

        ".config/systemd/user/xdg-desktop-portal-gnome.service.d/override.conf" = {
          generator = lib.generators.toINI {};
          value = {
            Service = {
              Restart = "always";
            };
            Unit = {
              After = "xdg-desktop-portal-gtk.service";
            };
          };
        };

        ".config/systemd/user/xdg-desktop-portal-gtk.service.d/override.conf" = {
          generator = lib.generators.toINI {};
          value = {
            Service = {
              Restart = "always";
            };
            Unit = {
              After = "xdg-desktop-portal.service";
              Wants = "xdg-desktop-portal-gnome.service";
            };
          };
        };

        ".config/systemd/user/xdg-desktop-portal.service.d/override.conf" = {
          generator = lib.generators.toINI {};
          value = {
            Service = {
              Restart = "always";
            };
            Unit = {
              Wants = "xdg-desktop-portal-gtk.service";
            };
          };
        };
      };
    };

    systemd.user.targets.niri-session = {
      wants = [
        "xdg-desktop-portal.service"
        "xdg-desktop-portal-gtk.service"
        "xdg-desktop-portal-gnome.service"
      ];
    };
  };
}
