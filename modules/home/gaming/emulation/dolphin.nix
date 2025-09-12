{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.gaming.emulation.gcn-wii;
in {
  options.home.gaming.emulation.gcn-wii = {
    enable = lib.mkEnableOption "GameCube and Wii emulation via Dolphin";
  };
  config = lib.mkIf cfg.enable {
    usr.packages = [
      pkgs.dolphin-emu
    ];
  };
}
