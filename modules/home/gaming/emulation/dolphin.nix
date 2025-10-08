{
  config,
  pkgs,
  lib,
  ...
}: {
  options.home.gaming.emulation.gcn-wii = {
    enable = lib.mkEnableOption "GameCube and Wii emulation via Dolphin";
  };
  config = lib.mkIf config.home.gaming.emulation.gcn-wii.enable {
    environment.systemPackages = [
      pkgs.dolphin-emu
    ];
  };
}
