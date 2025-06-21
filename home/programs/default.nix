###############################################################################
# Programs Modules Collection (Maid)
# Imports all program-related Home modules
###############################################################################
{helpers, ...}: {
  imports = helpers.importModules ./. ++ helpers.importDirs ./.;
}
