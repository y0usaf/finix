{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.hyprland;
  generators = import ../../../../lib/generators {inherit lib;};
in {
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];

      files.".config/xdg-desktop-portal/hyprland-portals.conf" = {
        text = generators.toINI {} {
          preferred = {
            default = "hyprland;gtk";
          };
        };
      };
    };
  };
}
