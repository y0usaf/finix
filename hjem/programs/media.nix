###############################################################################
# Media Module
# Configuration for media playback, streaming, and audio control
# - Audio control with pavucontrol
# - Video playback with VLC and Stremio
# - Media downloading with yt-dlp and ffmpeg
# - Terminal music playback with cmus
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.programs.media;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.programs.media = {
    enable = lib.mkEnableOption "media applications";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      pavucontrol # Sound mixer for PulseAudio
      ffmpeg # Multimedia framework
      vlc # Versatile media player
      stremio # Media streaming application
      cmus # Terminal-based music player
    ];
  };
}
