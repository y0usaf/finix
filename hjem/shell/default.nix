###############################################################################
# Shell Modules Collection
# Imports all shell-related Hjem modules
###############################################################################
{helpers, ...}: {
  imports = helpers.importModules ./.;
}
