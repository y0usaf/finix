#===============================================================================
#                          🖥️ NixOS Configuration 🖥️
#===============================================================================
# This file details the entire NixOS system configuration, including
# core system settings, package management, boot/hardware configuration,
# services, security policies, user settings, and more.
#
# Every section has been extensively commented for clarity.
#
# ⚠️  Root access required | System rebuild needed for changes
#===============================================================================
# Import the shared desktop configuration
{...}: {
  imports = [
    ../configurations/default.nix
    ./hardware-configuration.nix
  ];
}
