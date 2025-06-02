###############################################################################
# Gaming Module - Hjem Version
# Master import file for all gaming-related modules
###############################################################################
{
  lib,
  helpers,
  ...
}: {
  imports = helpers.importModules ./. ++ helpers.importDirs ./.;

  options.cfg.hjome.gaming = {
    enable = lib.mkEnableOption "gaming module";

    controllers = {
      enable = lib.mkEnableOption "gaming controller support";
    };

    emulation = {
      # Options will be defined in respective module files
    };

    minecraft = {
      enable = lib.mkEnableOption "Minecraft client and server support";
    };
  };
}
