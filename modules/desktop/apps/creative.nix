{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/Pinta"
  ];
  environment.systemPackages = [
    pkgs.pinta
    pkgs.gimp
  ];
}
