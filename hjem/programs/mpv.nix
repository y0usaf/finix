###############################################################################
# MPV Media Player Module
# Provides the mpv media player
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.hjome.programs.mpv;
in {
  options.cfg.hjome.programs.mpv = {
    enable = lib.mkEnableOption "mpv media player";
  };
  config = lib.mkIf cfg.enable {
    packages = with pkgs; [mpv];
  };
}