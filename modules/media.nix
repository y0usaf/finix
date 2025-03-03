#===============================================================================
#                      🎬 Media Configuration 🎬
#===============================================================================
# 🔊 Audio control with pavucontrol
# 🎞️ Video playback with VLC and Stremio
# 📥 Media downloading with yt-dlp and ffmpeg
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = lib.mkIf (builtins.elem "media" profile.features) {
    # Add media-related packages
    home.packages = with pkgs; [
      pavucontrol    # Sound mixer for PulseAudio
      ffmpeg         # Multimedia framework
      yt-dlp-light   # Lightweight tool for downloading videos
      vlc            # Versatile media player
      stremio        # Media streaming application
      cmus           # Terminal-based music player
    ];
  };
} 