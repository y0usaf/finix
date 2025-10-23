{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.gaming.emulation.gcn-wii = {
    enable = lib.mkEnableOption "GameCube and Wii emulation via Dolphin";
  };
  config = lib.mkIf config.user.gaming.emulation.gcn-wii.enable {
    environment.systemPackages = [
      pkgs.dolphin-emu
    ];
  };
}
