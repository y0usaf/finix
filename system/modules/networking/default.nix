###############################################################################
# Networking Configuration Module
# Network management settings:
# - NetworkManager configuration
# - Network-related settings
###############################################################################
{lib, ...}: {
  imports = (import ../../../lib/helpers/import-modules.nix {inherit lib;}) ./.;
}
