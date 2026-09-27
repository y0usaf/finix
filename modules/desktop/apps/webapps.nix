{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/chromium"
  ];
  environment.systemPackages = [pkgs.ungoogled-chromium];
}
