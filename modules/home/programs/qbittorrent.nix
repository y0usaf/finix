{
  config,
  pkgs,
  lib,
  ...
}: {
  options.home.programs.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent torrent client";
  };
  config = lib.mkIf config.home.programs.qbittorrent.enable {
    environment.systemPackages = [
      pkgs.qbittorrent
    ];
  };
}
