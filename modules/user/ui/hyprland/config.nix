{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.hyprland.enable {
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
            preload = ${config.user.directories.wallpapers.static.path}
            wallpaper = ,${config.user.directories.wallpapers.static.path}
            splash = false
            ipc = on
          '';
        };
      };
    };
  };
}
