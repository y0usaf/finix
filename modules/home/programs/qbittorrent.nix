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
  cfg = config.modules.programs.qbittorrent;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.programs.qbittorrent = {
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
