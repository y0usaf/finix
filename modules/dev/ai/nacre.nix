{config, ...}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/nacre"
    ".local/state/nacre"
  ];
}
