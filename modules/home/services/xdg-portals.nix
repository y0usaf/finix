{
  config,
  lib,
  pkgs,
  ...
}: let
  generators = import ../../../lib/generators {inherit lib;};
in {
  config = {
    hjem.users.${config.user.name} = {
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
