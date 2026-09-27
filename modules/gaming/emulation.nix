{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/Cemu"
    ".local/share/Cemu"
    ".local/share/dolphin-emu"
  ];
  environment.systemPackages = [
    pkgs.dolphin-emu
    pkgs.cemu
  ];
}
