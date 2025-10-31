{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.gaming.core = {
    enable = lib.mkEnableOption "core gaming packages";
  };
  config = lib.mkIf config.user.gaming.core.enable {
    environment.systemPackages = [
      pkgs.prismlauncher
      pkgs.gamescope
      pkgs.gamemode
      pkgs.protontricks
    ];
  };
}
