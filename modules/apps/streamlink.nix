###############################################################################
# Streamlink Module
# Provides configuration for the Streamlink CLI streaming utility
# - Configures Streamlink with optimal settings
# - Adds convenient shell aliases for YouTube and Twitch
# - Includes Twitch chat integration with Firefox
###############################################################################
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  cfg = config.modules.apps.streamlink;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.apps.streamlink = {
    enable = lib.mkEnableOption "streamlink streaming utility";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      streamlink
    ];

    ###########################################################################
    # Configuration Files
    ###########################################################################
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

    ###########################################################################
    # Shell Configuration
    ###########################################################################
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
