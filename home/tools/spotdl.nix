###############################################################################
# SpotDL Module
# Tools for downloading music from Spotify
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.home.tools.spotdl;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.tools.spotdl = {
    enable = lib.mkEnableOption "SpotDL music downloading tools";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      ffmpeg # Required for media conversion
    ];

    ###########################################################################
    # Shell Aliases (added to .zshrc)
    ###########################################################################
    users.users.y0usaf.maid.file.home.".zshrc".text = lib.mkAfter ''

      # ----------------------------
      # SpotDL Aliases
      # ----------------------------
      # SpotDL aliases for downloading music
      alias spotm4a="uvx spotdl --format m4a --output '{title}'"
      alias spotmp3="uvx spotdl --format mp3 --output '{title}'"
    '';
  };
}
