#===============================================================================
#                      🔄 Syncthing Configuration 🔄
#===============================================================================
# Continuous file synchronization program that synchronizes files between
# multiple devices. It's secure, decentralized, and open source.
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = {
    # Enable Syncthing service
    services.syncthing = {
      enable = true;
      tray.enable = false;
    };

    # Add Syncthing package
    home.packages = with pkgs; [
      syncthing # File synchronization tool
    ];
  };
}
