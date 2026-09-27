{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent torrent client";
  };
  config = lib.mkIf config.user.programs.qbittorrent.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/qBittorrent"
    ];
    environment.systemPackages = [
      pkgs.qbittorrent
    ];
  };
}
