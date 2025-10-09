{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.user.ui.hyprland.enable {
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
