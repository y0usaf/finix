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
  cfg = config.cfg.hjome.gaming;
in {
  config = lib.mkIf cfg.enable {
    packages = with pkgs; [
      steam
      protonup-qt
      gamemode
      protontricks
      prismlauncher
    ];
  };
}
