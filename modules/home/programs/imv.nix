{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.imv;
in {
  options.home.programs.imv = {
    enable = lib.mkEnableOption "imv image viewer";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.imv];
  };
}
