###############################################################################
# Gaming Module
# Master import file for all gaming-related modules
###############################################################################
{lib, helpers, ...}: {
  imports = helpers.importModules ./. ++ helpers.importDirs ./.;
  
  options.cfg.gaming.emulation = {
    wii-u.enable = lib.mkEnableOption "Wii U emulation via Cemu";
    gcn-wii.enable = lib.mkEnableOption "GameCube and Wii emulation via Dolphin";
  };
}