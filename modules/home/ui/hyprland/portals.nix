{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.hyprland;
in {
  config = lib.mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
      config = {
        hyprland = {
          default = ["hyprland" "gtk"];
        };
      };
    };
  };
}
