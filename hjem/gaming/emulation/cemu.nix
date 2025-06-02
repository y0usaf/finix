###############################################################################
# Cemu Emulator Module
# Configuration for Wii U emulation
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.gaming.emulation.wii-u;
in {
  options.cfg.hjome.gaming.emulation.wii-u = {
    enable = lib.mkEnableOption "Wii U emulation via Cemu";
  };

  config = lib.mkIf cfg.enable {
    packages = [
      pkgs.cemu
    ];
  };
}
