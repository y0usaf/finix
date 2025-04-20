###############################################################################
# 7z (p7zip) Archive Manager Module
# Provides the 7z command via p7zip
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.tools."7z";
in {
  options.cfg.tools."7z" = {
    enable = lib.mkEnableOption "7z (p7zip) archive manager";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ p7zip ];
  };
}
