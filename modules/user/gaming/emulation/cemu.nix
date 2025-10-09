{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.gaming.emulation.wii-u = {
    enable = lib.mkEnableOption "Wii U emulation via Cemu";
  };
  config = lib.mkIf config.user.gaming.emulation.wii-u.enable {
    environment.systemPackages = [
      pkgs.cemu
    ];
  };
}
