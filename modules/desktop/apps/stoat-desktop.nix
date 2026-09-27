{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/stoat-desktop"
  ];
  environment.systemPackages = [pkgs.stoat-desktop];
}
