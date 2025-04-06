###############################################################################
# qBittorrent Module
# Provides the qBittorrent torrent client
# - Lightweight BitTorrent client
# - Web UI for remote management
# - Advanced torrent management features
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.apps.qbittorrent;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.apps.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent torrent client";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      qbittorrent
    ];
  };
}
