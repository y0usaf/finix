###############################################################################
# Core Modules Collection (Maid)
# Imports all core-related Home modules
###############################################################################
{lib, ...}: {
  imports = lib.importModules ./.;
}
