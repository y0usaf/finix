{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  cfg = config.home.ui.hyprland;
  generators = import ../../../../lib/generators/toHyprconf.nix lib;
in {
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = [
        pkgs.hyprwayland-scanner
        pkgs.hyprland # Use nixpkgs version for npins compatibility
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.jq
        pkgs.swaybg
      ];
      files = {
        ".config/hypr/hyprland.conf" = {
          clobber = true;
          text = let
            pluginsConfig = lib.optionalString cfg.hy3.enable (
              generators.pluginsToHyprconf [
                (
                  if cfg.flake.enable
                  then inputs.hy3.packages.${pkgs.system}.hy3
                  else pkgs.hyprlandPlugins.hy3
                )
              ] ["$"]
            );
          in
            lib.optionalString (pluginsConfig != "") pluginsConfig;
        };
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
