{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.programs.qbittorrent;
in {
  options.home.programs.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent torrent client";
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = with pkgs; [
      qbittorrent
    ];
  };
}
