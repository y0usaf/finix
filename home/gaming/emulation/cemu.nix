###############################################################################
# Cemu Emulator Module - Nix-Maid Version
# Configuration for Wii U emulation
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.gaming.emulation.wii-u;
in {
  options.home.gaming.emulation.wii-u = {
    enable = lib.mkEnableOption "Wii U emulation via Cemu";
  };

  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = [
      pkgs.cemu
    ];
  };
}
