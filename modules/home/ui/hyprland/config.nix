{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.ui.hyprland;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.hyprwayland-scanner
      pkgs.hyprland
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
      pkgs.jq
      pkgs.swaybg
      pkgs.xwayland
    ];
    usr = {
      files = {
        ".config/hypr/hyprpaper.conf" = {
          clobber = true;
          text = ''
            preload = ${config.home.directories.wallpapers.static.path}
            wallpaper = ,${config.home.directories.wallpapers.static.path}
            splash = false
            ipc = on
          '';
        };
      };
    };
  };
}
