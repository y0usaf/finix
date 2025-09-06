{
  config,
  lib,
  ...
}: let
  cfg = config.home.ui.hyprland;
  generators = import ../../../../lib/generators {inherit lib;};
in {
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.files.".config/xdg-desktop-portal/hyprland-portals.conf" = {
      text = generators.toINI {} {
        preferred = {
          default = "hyprland;gtk";
        };
      };
    };
  };
}
