{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".local/share/dolphin-emu"
  ];
  environment.systemPackages = [
    pkgs.dolphin-emu
  ];
}
