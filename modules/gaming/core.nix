{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.gaming.core = {
    enable = lib.mkEnableOption "core gaming packages";
  };
  config = lib.mkIf config.user.gaming.core.enable {
    users.users."${config.user.name}".extraGroups = ["gamemode"];
    environment.systemPackages = [
      pkgs.prismlauncher
      pkgs.gamescope
      pkgs.gamemode
      pkgs.protontricks
    ];
  };
}
