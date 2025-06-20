###############################################################################
# Claude Code Development Environment (Maid Version)
# Provides Claude Code integration and development tools
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.claude-code;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.dev.claude-code = {
    enable = lib.mkEnableOption "claude code development environment";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      claude-code
    ];
  };
}
