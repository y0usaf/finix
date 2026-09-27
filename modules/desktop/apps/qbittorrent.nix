{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/qBittorrent"
  ];
  environment.systemPackages = [
    pkgs.qbittorrent
  ];
}
