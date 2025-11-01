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
      pkgs.wl-clipboard-rs
      pkgs.jq
      pkgs.swaybg
      pkgs.xwayland
    ];
    usr = {
      files = {
        ".config/hypr/hyprpaper.conf" = {
          clobber = true;
          text = ''
            preload = ${config.user.paths.wallpapers.static.path}
            wallpaper = ,${config.user.paths.wallpapers.static.path}
            splash = false
            ipc = on
          '';
        };
      };
    };
  };
}
