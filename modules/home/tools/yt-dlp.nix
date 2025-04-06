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
  cfg = config.modules.tools.yt-dlp;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.tools.yt-dlp = {
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
      # Discord-compatible MP4 (H.264/AAC, smaller size)
      ytmp4 = "uvx yt-dlp -f 'bv*[height<=720]+ba/b[height<=720]' --recode-video mp4 --postprocessor-args 'ffmpeg:-c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k -vf scale=-2:720' -o '%(title)s.%(ext)s'";
      # Discord-compatible smaller MP4 for larger videos
      ytmp4s = "uvx yt-dlp -f 'bv*[height<=480]+ba/b[height<=480]' --recode-video mp4 --postprocessor-args 'ffmpeg:-c:v libx264 -crf 26 -preset faster -c:a aac -b:a 96k -vf scale=-2:480' -o '%(title)s.%(ext)s'";
      ytwebm = "uvx yt-dlp -f 'bv*[height<=720]+ba/b[height<=720]' --recode-video webm --postprocessor-args 'ffmpeg:-c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus -vf scale=-2:720' -o '%(title)s.%(ext)s'";
      # Discord-friendly - 8MB limit version
      ytdiscord = "uvx yt-dlp -f 'bv*[height<=720]+ba/b[height<=720]' --recode-video mp4 --postprocessor-args 'ffmpeg:-c:v libx264 -crf 28 -preset faster -c:a aac -b:a 96k -vf scale=-2:min(720\\,ih) -fs 7.8M' -o '%(title)s_discord.%(ext)s'";
    };
  };
}
