###############################################################################
# Claude Code Development Module (Maid Version)
# Configures Claude Code and related tools using nix-maid
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
    enable = lib.mkEnableOption "Claude Code development tools";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        claude-code
        gemini-cli
      ];

      ###########################################################################
      # Global Claude Configuration
      ###########################################################################
      file.home = {
        ".claude/CLAUDE.md".text = builtins.readFile ../../CLAUDE.md;
      };
    };
  };
}