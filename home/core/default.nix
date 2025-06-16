###############################################################################
# Core Modules Collection (Maid)
# Imports all core-related Home modules
###############################################################################
{helpers, ...}: {
  imports = helpers.importModules ./.;
}
