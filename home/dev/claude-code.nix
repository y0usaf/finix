###############################################################################
# Claude Code IDE Configuration
# Installs and configures Claude Code AI assistant for development
# - Installs Claude Code via npm
# - Installs Brave Search integration
# - Configures PATH for global npm binaries
###############################################################################
{
  config,
  pkgs,
  lib,
  host,
  ...
}: let
  cfg = config.cfg.dev.claude-code;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code AI assistant";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      nodejs_20
    ];

    ###########################################################################
    # Installation
    ###########################################################################
    home.activation.installClaudeCode = lib.hm.dag.entryAfter ["npmSetup"] ''
      # Install Claude Code and Brave Search globally via npm
      ${pkgs.nodejs_20}/bin/npm install -g @anthropic-ai/claude-code @modelcontextprotocol/server-brave-search
    '';

    ###########################################################################
    # Environment Configuration
    ###########################################################################
    # Add npm bin directory to PATH to ensure claude-code is accessible
    home.sessionPath = [
      "${config.xdg.dataHome}/npm/bin"
    ];
  };
}
