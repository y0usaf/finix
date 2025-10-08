{
  config,
  pkgs,
  lib,
  ...
}: {
  options.home.gaming.core = {
    enable = lib.mkEnableOption "core gaming packages";
  };
  config = lib.mkIf config.home.gaming.core.enable {
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
