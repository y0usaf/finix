###############################################################################
# Dolphin Emulator Module
# Configuration for GameCube and Wii emulation
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.programs.gaming.emulation.gcn-wii;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.dolphin-emu
    ];
  };
}