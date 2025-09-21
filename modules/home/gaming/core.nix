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
    environment.systemPackages = with pkgs; [
      steam
      gamescope
      protonup-rs
      gamemode
      protontricks
      prismlauncher
    ];
  };
}
