###############################################################################
# IMV Image Viewer Module
# Provides the imv image viewer
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.programs.imv;
in {
  options.cfg.programs.imv = {
    enable = lib.mkEnableOption "imv image viewer";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ imv ];
  };
}
