###############################################################################
# 🔄 Syncthing Configuration
# Continuous file synchronization program that synchronizes files between
# multiple devices. It's secure, decentralized, and open source.
# - Secure file synchronization across devices
# - Decentralized architecture (no central server)
# - Open source and privacy-focused
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.programs.syncthing;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.programs.syncthing = {
    enable = lib.mkEnableOption "syncthing file synchronization";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Systemd Services
    ###########################################################################
    services.syncthing = {
      enable = true;
      tray.enable = false;
    };

    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      syncthing # File synchronization tool
    ];
  };
}
