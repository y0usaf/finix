###############################################################################
# Shell Modules Collection (Maid)
# Imports all shell-related Home modules
###############################################################################
{lib, ...}: {
  imports = lib.importModules ./.;
}
