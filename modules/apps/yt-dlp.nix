###############################################################################
# YouTube-DLP Module
# Provides tools for downloading and converting media from YouTube and other sites
# - Requires Python module for UV package manager
# - Provides convenient aliases for different media formats
# - Integrates with ffmpeg for conversion
###############################################################################
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  cfg = config.modules.apps.media.yt-dlp;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.apps.media.yt-dlp = {
    enable = lib.mkEnableOption "YouTube-DLP media conversion tools";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf (cfg.enable && config.modules.dev.python.enable) {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      yt-dlp-light # Lightweight tool for downloading videos
      ffmpeg # Required for media conversion
    ];

    ###########################################################################
    # Shell Aliases
    ###########################################################################
    programs.zsh.shellAliases = {
      ytm4a = "uvx yt-dlp -x --audio-format m4a -o '%(title)s.%(ext)s'";
      ytmp3 = "uvx yt-dlp -x --audio-format mp3 -o '%(title)s.%(ext)s'";
      ytmp4 = "uvx yt-dlp -f 'bv*+ba/b' --recode-video mp4 --postprocessor-args 'ffmpeg:-c:v libx264 -c:a aac' -o '%(title)s.%(ext)s'";
      ytwebm = "uvx yt-dlp -f 'bv*+ba/b' --recode-video webm -o '%(title)s.%(ext)s'";
    };
  };
}
