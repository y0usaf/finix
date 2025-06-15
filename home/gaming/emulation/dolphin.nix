###############################################################################
# Dolphin Emulator Module - Nix-Maid Version
# Configuration for GameCube and Wii emulation
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.home.gaming.emulation.gcn-wii;
in {
  options.cfg.home.gaming.emulation.gcn-wii = {
    enable = lib.mkEnableOption "GameCube and Wii emulation via Dolphin";
  };

  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = [
      pkgs.dolphin-emu
    ];
  };
}
