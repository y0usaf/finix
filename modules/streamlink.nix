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

      # Twitch specific
      twitch-low-latency
      twitch-disable-ads

      # Interface settings
      quiet
    '';

    # Add convenient shell aliases
    programs.zsh = {
      shellAliases = {
        youtube = "streamlink https://youtube.com/watch?v=";
      };
      
      initExtra = ''
        function twitch() {
          if [ -z "$1" ]; then
            echo "Usage: twitch <channel_name>"
            return 1
          fi
          channel="$1"
          echo "Opening chat for channel: $channel"
          firefox "https://www.twitch.tv/popout/$channel/chat?popout=" &
          echo "Starting stream for channel: $channel"
          streamlink "https://www.twitch.tv/$channel" best
        }
      '';
    };
  };
}