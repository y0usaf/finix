###############################################################################
# SpotDL Module
# Provides tools for downloading music from Spotify
# - Requires Python module for UV package manager
# - Provides convenient aliases for different audio formats
# - Integrates with ffmpeg for conversion
###############################################################################
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  cfg = config.modules.apps.media.spotdl;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.apps.media.spotdl = {
    enable = lib.mkEnableOption "SpotDL music downloading tools";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf (cfg.enable && config.modules.dev.python.enable) {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      ffmpeg # Required for media conversion
    ];

    ###########################################################################
    # Shell Aliases
    ###########################################################################
    programs.zsh.shellAliases = {
      spotm4a = "uvx spotdl --format m4a --output '{title}'";
      spotmp3 = "uvx spotdl --format mp3 --output '{title}'";
    };
  };
}
