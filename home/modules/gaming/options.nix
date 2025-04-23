# modules/home/gaming/options.nix
# Defines the gaming module options
{lib, ...}: {
  options.cfg.programs.gaming = {
    enable = lib.mkEnableOption "gaming module";

    controllers = {
      enable = lib.mkEnableOption "gaming controller support";
    };

    emulation = {
      wii-u = {
        enable = lib.mkEnableOption "Wii U emulation via Cemu";
      };

      gcn-wii = {
        enable = lib.mkEnableOption "GameCube and Wii emulation via Dolphin";
      };
    };
  };
}
