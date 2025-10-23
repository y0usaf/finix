{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.programs.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent torrent client";
  };
  config = lib.mkIf config.user.programs.qbittorrent.enable {
    environment.systemPackages = [
      pkgs.qbittorrent
    ];
  };
}
