###############################################################################
# Hardware Configuration Modules
# Centralized hardware-specific configurations:
# - Input devices (keyboards, controllers)
# - Video devices (cameras, capture)
# - Graphics configuration
# - I2C bus for hardware monitoring
# - AMD GPU configuration
# - Bluetooth stack configuration
###############################################################################
{lib, ...}: {
  imports = (import ../../../lib/helpers/import-modules.nix {inherit lib;}) ./.;
}
