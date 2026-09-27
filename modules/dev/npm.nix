{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.files = [
    ".npmrc"
  ];
  environment.systemPackages = [
    pkgs.nodejs
  ];
}
