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
    hjem.users.${config.user.name}.packages = with pkgs; [
      qbittorrent
    ];
  };
}
