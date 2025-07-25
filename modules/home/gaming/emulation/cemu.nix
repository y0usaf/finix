{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.gaming.emulation.wii-u;
in {
  options.home.gaming.emulation.wii-u = {
    enable = lib.mkEnableOption "Wii U emulation via Cemu";
  };
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid.packages = [
      pkgs.cemu
    ];
  };
}
