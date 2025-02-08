{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  # Only enable if streamlink feature is selected
  config = {
    home.packages = with pkgs; [
      streamlink
   ];

    # Create Streamlink configuration
    xdg.configFile."streamlink/config".text = ''
      # Player settings
      player=${profile.defaultMediaPlayer.command}
      player-no-close
      player-continuous-http

      # Quality settings
      default-stream=best
      stream-sorting-excludes=>4000k,>1080p

      # Network settings
      ringbuffer-size=64M
      hls-segment-threads=3

      # Twitch specific
      twitch-low-latency
      twitch-disable-ads

      # Interface settings
      force-progress
      quiet
    '';

    # Add convenient shell aliases
    programs.zsh.shellAliases = {
      twitch = "streamlink twitch.tv/";
      youtube = "streamlink youtube.com/watch?v=";
    };
  };
}