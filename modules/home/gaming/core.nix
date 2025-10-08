{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.gaming.core;
in {
  options.home.gaming.core = {
    enable = lib.mkEnableOption "core gaming packages";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.steam
      pkgs.gamescope
      pkgs.protonup-rs
      pkgs.gamemode
      pkgs.protontricks
      pkgs.prismlauncher
    ];
  };
}
