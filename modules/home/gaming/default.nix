###############################################################################
# Gaming Module
# Configuration for gaming-related software and optimizations
# - Steam and Proton configuration
# - Game-specific settings and mods
# - Performance optimization tools
# - Emulation support
###############################################################################
{
  config,
  pkgs,
  lib,
  host,
  ...
}: let
  cfg = config.cfg.programs.gaming;
in {
  imports = [
    ./mods.nix
    ./marvel-rivals
    ./wukong
  ];

  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.programs.gaming = {
    enable = lib.mkEnableOption "gaming module";

    emulation = {
      wii-u = {
        enable = lib.mkEnableOption "Wii U emulation via Cemu";
      };

      gcn-wii = {
        enable = lib.mkEnableOption "GameCube and Wii emulation via Dolphin";
      };
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs;
      [
        steam
        protonup-qt
        gamemode
        protontricks
        prismlauncher
      ]
      ++ lib.optionals cfg.emulation.wii-u.enable [pkgs.cemu]
      ++ lib.optionals cfg.emulation.gcn-wii.enable [pkgs.dolphin-emu];
  };
}