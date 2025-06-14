###############################################################################
# Shell Modules Collection (Maid)
# Imports all shell-related Home modules
###############################################################################
{helpers, ...}: {
  imports = helpers.importModules ./.;
}