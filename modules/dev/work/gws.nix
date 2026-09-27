{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/gws"
    ".config/gws-inscend"
  ];
  environment.systemPackages = [pkgs.gws];
}
