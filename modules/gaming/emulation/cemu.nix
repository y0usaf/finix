{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.gaming.emulation.wii-u = {
    enable = lib.mkEnableOption "Wii U emulation via Cemu";
  };
  config = lib.mkIf config.user.gaming.emulation.wii-u.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/Cemu"
      ".local/share/Cemu"
    ];
    environment.systemPackages = [
      pkgs.cemu
    ];
  };
}
