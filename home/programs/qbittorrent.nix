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
  cfg = config.home.programs.qbittorrent;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.programs.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent torrent client";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      qbittorrent
    ];
  };
}
