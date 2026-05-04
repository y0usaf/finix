{
  config,
  lib,
  pkgs,
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
    manzil.users."${config.user.name}" = {
      files = {
        ".config/hypr/hyprpaper.conf" = {
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
