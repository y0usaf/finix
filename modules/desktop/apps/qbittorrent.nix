{pkgs, ...}: {
  user.persist.directories = [".config/qBittorrent"];
  environment.systemPackages = [pkgs.qbittorrent];
}
