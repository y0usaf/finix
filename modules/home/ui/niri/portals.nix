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
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      
      files.".config/xdg-desktop-portal/niri-portals.conf" = {
        text = generators.toINI {} {
          preferred = {
            default = "gtk;gnome";
            "org.freedesktop.impl.portal.ScreenCast" = "gnome";
          };
        };
      };
    };
  };
}
