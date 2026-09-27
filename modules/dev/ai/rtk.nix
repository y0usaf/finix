{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".local/share/rtk"
  ];
  environment.systemPackages = [
    pkgs.rtk
  ];
}
