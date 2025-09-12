{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.hyprland;
in {
  config = lib.mkIf cfg.enable {
    usr = {
      packages = with pkgs; [
        xdg-desktop-portal
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];

      files.".config/xdg-desktop-portal/hyprland-portals.conf" = {
        generator = lib.generators.toINI {};
        value = {
          preferred = {
            default = "hyprland;gtk";
          };
        };
      };
    };
  };
}
