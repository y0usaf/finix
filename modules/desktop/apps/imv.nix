{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.imv = {
    enable = lib.mkEnableOption "imv image viewer";
  };
  config = lib.mkIf config.user.programs.imv.enable {
    environment.systemPackages = [pkgs.imv];
  };
}
