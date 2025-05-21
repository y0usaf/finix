###############################################################################
# Core Gaming Module
# Base configuration for gaming-related software
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.programs.gaming;
in {
  options.cfg.programs.gaming = {
    enable = lib.mkEnableOption "gaming module";
  };
  
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      steam
      protonup-qt
      gamemode
      protontricks
      prismlauncher
    ];
  };
}