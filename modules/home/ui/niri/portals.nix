{
  config,
  lib,
  ...
}: let
  cfg = config.home.ui.niri;
  generators = import ../../../../lib/generators {inherit lib;};
in {
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.files.".config/xdg-desktop-portal/niri-portals.conf" = {
      text = generators.toINI {} {
        preferred = {
          default = "gtk;gnome";
          "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        };
      };
    };
  };
}
