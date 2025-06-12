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
      # NPM setup and Claude Code installation script
      ".local/bin/setup-claude-code" = {
        text = ''
          #!/bin/bash
          # Set up NPM environment
          export NPM_CONFIG_PREFIX=~/.local/share/npm
          export NPM_CONFIG_CACHE=~/.cache/npm
          export NPM_CONFIG_USERCONFIG=~/.config/npm/npmrc
          export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"
          export PATH="$HOME/.local/share/npm/bin:$PATH"
          
          # Create directories
          mkdir -p ~/.local/share/npm
          mkdir -p ~/.cache/npm
          mkdir -p ~/.config/npm/config
          mkdir -p "$XDG_RUNTIME_DIR/npm"
          
          # Install Claude Code and Brave Search globally via npm
          ${pkgs.nodejs_20}/bin/npm install -g @anthropic-ai/claude-code @modelcontextprotocol/server-brave-search
        '';
        executable = true;
      };

      # NPM configuration for XDG compliance
      ".config/npm/npmrc".text = ''
        prefix=~/.local/share/npm
        cache=~/.cache/npm
        init-module=~/.config/npm/config/npm-init.js
        store-dir=~/.cache/pnpm/store
      '';

      # Shell integration
      ".zshrc".text = lib.mkBefore ''
        # NPM environment variables
        export NPM_CONFIG_PREFIX=~/.local/share/npm
        export NPM_CONFIG_CACHE=~/.cache/npm
        export NPM_CONFIG_USERCONFIG=~/.config/npm/npmrc
        export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"
        
        # Add npm bin directory to PATH for claude-code
        export PATH="$HOME/.local/share/npm/bin:$PATH"


      '';
    };
  };
}
