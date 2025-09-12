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
    usr.packages = with pkgs; [
      steam
      protonup-rs
      gamemode
      protontricks
      prismlauncher
    ];
  };
}
