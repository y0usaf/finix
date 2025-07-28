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
    hjem.users.${config.user.name}.packages = with pkgs; [
      steam
      protonup-qt
      gamemode
      protontricks
      prismlauncher
    ];
  };
}
