###############################################################################
# Tools Modules Collection (Maid)
# Imports all tools-related Home modules
###############################################################################
{lib, ...}: {
  imports = lib.importModules ./.;
}
