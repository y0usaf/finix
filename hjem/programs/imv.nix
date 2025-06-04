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
  cfg = config.cfg.hjome.programs.imv;
in {
  options.cfg.hjome.programs.imv = {
    enable = lib.mkEnableOption "imv image viewer";
  };
  config = lib.mkIf cfg.enable {
    packages = with pkgs; [imv];
  };
}
