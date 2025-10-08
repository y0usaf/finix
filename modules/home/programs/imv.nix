{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.programs.imv = {
    enable = lib.mkEnableOption "imv image viewer";
  };
  config = lib.mkIf config.home.programs.imv.enable {
    environment.systemPackages = [pkgs.imv];
  };
}
