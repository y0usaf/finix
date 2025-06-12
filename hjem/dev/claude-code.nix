###############################################################################
# Claude Code IDE Configuration (Hjem Version)
# Installs and configures Claude Code AI assistant for development
# - Installs Claude Code via npm
# - Installs Brave Search integration
# - Configures PATH for global npm binaries
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.dev.claude-code;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code AI assistant";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      nodejs_20
    ];

    ###########################################################################
    # Configuration Files
    ###########################################################################
    files = {
      # NPM setup script for Claude Code installation
      ".local/bin/install-claude-code" = {
        text = ''
          #!/bin/bash
          # Install Claude Code and Brave Search globally via npm
          ${pkgs.nodejs_20}/bin/npm install -g @anthropic-ai/claude-code @modelcontextprotocol/server-brave-search
        '';
        executable = true;
      };

      # Shell integration
      ".zshrc".text = ''
        # Add npm bin directory to PATH for claude-code
        export PATH="$HOME/.local/share/npm/bin:$PATH"

        # Claude Code aliases
        alias claude-code='npx @anthropic-ai/claude-code'
      '';
    };
  };
}
