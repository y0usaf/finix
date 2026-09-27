{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/Cemu"
    ".local/share/Cemu"
  ];
  environment.systemPackages = [
    pkgs.cemu
  ];
}
