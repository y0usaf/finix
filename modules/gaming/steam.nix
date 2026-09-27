{config, ...}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".SteamCloud"
    ".steam"
  ];
}
