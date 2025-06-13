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
      "${config.xdg.configDirectory}/npm/npmrc".text = ''
        prefix=${config.xdg.dataDirectory}/npm
        cache=${config.xdg.cacheDirectory}/npm
        init-module=${config.xdg.configDirectory}/npm/config/npm-init.js
        store-dir=${config.xdg.cacheDirectory}/pnpm/store
      '';

      # NPM setup script
      "${config.xdg.dataDirectory}/bin/npm-setup" = {
        text = ''
          #!/bin/bash
          # Set up NPM directories
          mkdir -p ${config.xdg.dataDirectory}/npm
          mkdir -p ${config.xdg.cacheDirectory}/npm
          mkdir -p ${config.xdg.configDirectory}/npm/config
          mkdir -p ${config.xdg.cacheDirectory}/pnpm/store
          mkdir -p "$XDG_RUNTIME_DIR/npm"
        '';
        executable = true;
      };

      # Shell integration
      ".zshrc".text = lib.mkBefore ''
        # NPM environment variables
        export NPM_CONFIG_PREFIX=${config.xdg.dataDirectory}/npm
        export NPM_CONFIG_CACHE=${config.xdg.cacheDirectory}/npm
        export NPM_CONFIG_USERCONFIG=${config.xdg.configDirectory}/npm/npmrc
        export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"

        # Add npm bin directory to PATH
        export PATH="${config.xdg.dataDirectory}/npm/bin:$PATH"
      '';
    };
  };
}
