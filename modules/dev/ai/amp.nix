{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/amp"
    ".local/share/amp"
  ];
  environment.systemPackages = [
    pkgs.amp-cli
  ];
}
