{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    qbittorrent
  ];
}
