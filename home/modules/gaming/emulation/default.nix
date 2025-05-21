###############################################################################
# Gaming Emulation Module
# Master import file for all emulation-related modules
###############################################################################
{lib, ...}: {
  imports = (import ../../../../lib/helpers/import-modules.nix {inherit lib;}) ./.;
  
  options.cfg.programs.gaming.emulation = {
    wii-u.enable = lib.mkEnableOption "Wii U emulation via Cemu";
    gcn-wii.enable = lib.mkEnableOption "GameCube and Wii emulation via Dolphin";
  };
}