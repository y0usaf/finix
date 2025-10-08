{
  config,
  pkgs,
  lib,
  ...
}: {
  options.home.gaming.emulation.wii-u = {
    enable = lib.mkEnableOption "Wii U emulation via Cemu";
  };
  config = lib.mkIf config.home.gaming.emulation.wii-u.enable {
    environment.systemPackages = [
      pkgs.cemu
    ];
  };
}
