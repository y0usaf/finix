###############################################################################
# Node.js & NPM Configuration (Hjem Version)
# Configures Node.js runtime and NPM package management
# - XDG compliance for NPM directories
# - Global package installation support
# - Proper environment variable configuration
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.dev.npm;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.dev.npm = {
    enable = lib.mkEnableOption "Node.js and NPM configuration";
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
      # NPM global config - use XDG directories
      ".config/npm/npmrc".text = ''
        prefix=~/.local/share/npm
        cache=~/.cache/npm
        init-module=~/.config/npm/config/npm-init.js
        store-dir=~/.cache/pnpm/store
      '';

      # NPM setup script
      ".local/bin/npm-setup" = {
        text = ''
          #!/bin/bash
          # Set up NPM directories
          mkdir -p ~/.local/share/npm
          mkdir -p ~/.cache/npm
          mkdir -p ~/.config/npm/config
          mkdir -p ~/.cache/pnpm/store
          mkdir -p "$XDG_RUNTIME_DIR/npm"
        '';
        executable = true;
      };

      # Shell integration
      ".zshrc".text = ''
        # NPM environment variables
        export NPM_CONFIG_PREFIX=~/.local/share/npm
        export NPM_CONFIG_CACHE=~/.cache/npm
        export NPM_CONFIG_USERCONFIG=~/.config/npm/npmrc
        export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"

        # Add npm bin directory to PATH
        export PATH="$HOME/.local/share/npm/bin:$PATH"
      '';
    };
  };
}
