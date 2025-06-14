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
        prefix=$HOME/.local/share/npm
        cache=${config.xdg.cacheDirectory}/npm
        init-module=$HOME/.config/npm/config/npm-init.js
        store-dir=${config.xdg.cacheDirectory}/pnpm/store
      '';

      # NPM setup script
      ".local/share/bin/npm-setup" = {
        text = ''
          #!/bin/bash
          # Set up NPM directories
          mkdir -p $HOME/.local/share/npm
          mkdir -p ${config.xdg.cacheDirectory}/npm
          mkdir -p $HOME/.config/npm/config
          mkdir -p ${config.xdg.cacheDirectory}/pnpm/store
          mkdir -p "$XDG_RUNTIME_DIR/npm"
        '';
        executable = true;
      };

      # Shell integration
      ".zshrc".text = lib.mkBefore ''
        # NPM environment variables
        export NPM_CONFIG_PREFIX=$HOME/.local/share/npm
        export NPM_CONFIG_CACHE=${config.xdg.cacheDirectory}/npm
        export NPM_CONFIG_USERCONFIG=$HOME/.config/npm/npmrc
        export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"

        # Add npm bin directory to PATH
        export PATH="$HOME/.local/share/npm/bin:$PATH"
      '';
    };
  };
}
