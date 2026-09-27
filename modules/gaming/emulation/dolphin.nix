{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.gaming.emulation.gcn-wii = {
    enable = lib.mkEnableOption "GameCube and Wii emulation via Dolphin";
  };
  config = lib.mkIf config.user.gaming.emulation.gcn-wii.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".local/share/dolphin-emu"
    ];
    environment.systemPackages = [
      pkgs.dolphin-emu
    ];
  };
}
