###############################################################################
# Programs Modules Collection (Maid)
# Imports all program-related Home modules
###############################################################################
{lib, ...}: {
  imports = lib.importModules ./. ++ lib.importDirs ./.;
}
