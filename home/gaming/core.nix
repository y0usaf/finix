###############################################################################
# Core Gaming Module - Nix-Maid Version
# Base configuration for gaming-related software
###############################################################################
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
    users.users.y0usaf.maid.packages = with pkgs; [
      steam
      protonup-qt
      gamemode
      protontricks
      prismlauncher
    ];
  };
}
