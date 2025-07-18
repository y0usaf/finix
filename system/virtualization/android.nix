###############################################################################
# Android Virtualization Configuration
# Waydroid Android container support:
# - Waydroid Android emulation
###############################################################################
{
  lib,
  hostSystem,
  ...
}: {
  config = {
    ###########################################################################
    # Android Virtualization
    # Waydroid Android emulation - enabled based on host capability
    ###########################################################################
    virtualisation.waydroid = lib.mkIf (hostSystem.services.waydroid.enable or false) {
      enable = true; # Enable Waydroid to run Android apps on NixOS
    };
  };
}
