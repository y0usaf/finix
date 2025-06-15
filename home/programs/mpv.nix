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
  cfg = config.cfg.home.programs.mpv;
in {
  options.cfg.home.programs.mpv = {
    enable = lib.mkEnableOption "mpv media player";
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = with pkgs; [mpv];
  };
}
