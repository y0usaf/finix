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
  cfg = config.cfg.programs.mpv;
in {
  options.cfg.programs.mpv = {
    enable = lib.mkEnableOption "mpv media player";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ mpv ];
  };
}
