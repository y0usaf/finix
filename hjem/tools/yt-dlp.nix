###############################################################################
# YouTube-DLP Module
# Tools for downloading and converting media from YouTube and other sites
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.tools.yt-dlp;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.tools.yt-dlp = {
    enable = lib.mkEnableOption "YouTube-DLP media conversion tools";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      yt-dlp-light # Lightweight tool for downloading videos
      ffmpeg # Required for media conversion
    ];
  };
}