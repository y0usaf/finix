#===============================================================================
#                          💻 NixOS Laptop Configuration 💻
#===============================================================================
# This file imports the shared desktop configuration and laptop-specific hardware
# configuration, allowing for consistent settings across devices while maintaining
# hardware-specific configurations.
#
# ⚠️  Root access required | System rebuild needed for changes
#===============================================================================
{...}: {
  imports = [
    ../configurations/default.nix
    ./hardware-configuration.nix
  ];
}
