###############################################################################
# Boot Configuration Module
# Boot loader and kernel configurations:
# - Boot loader settings
# - EFI configuration
# - Kernel packages and modules
# - System control parameters
###############################################################################
{lib, ...}: {
  imports = (import ../../../lib/helpers/import-modules.nix {inherit lib;}) ./.;
}