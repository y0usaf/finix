###############################################################################
# Core System Configuration Modules
# Fundamental system configurations:
# - Nix package management
# - System-wide settings
# - Core system utilities
# - Dynamic linking support
###############################################################################
{lib, ...}: {
  imports = (import ../../../lib/helpers/import-modules.nix {inherit lib;}) ./.;
}
