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
  cfg = config.cfg.hjome.gaming.emulation.gcn-wii;
in {
  options.cfg.hjome.gaming.emulation.gcn-wii = {
    enable = lib.mkEnableOption "GameCube and Wii emulation via Dolphin";
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.dolphin-emu
    ];
  };
}
