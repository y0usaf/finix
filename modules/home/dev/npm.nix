###############################################################################
# Node.js & NPM Configuration
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
  cfg = config.cfg.dev.npm;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.dev.npm = {
    enable = lib.mkEnableOption "Node.js and NPM configuration";
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
    # Configuration Files
    ###########################################################################
    # NPM global config - use XDG directories
    xdg.configFile."npm/npmrc".text = ''
      prefix=${config.xdg.dataHome}/npm
      cache=${config.xdg.cacheHome}/npm
      init-module=${config.xdg.configHome}/npm/config/npm-init.js
      store-dir=${config.xdg.cacheHome}/pnpm/store
    '';

    ###########################################################################
    # Environment Variables
    ###########################################################################
    # Add npm bin directory to PATH
    home.sessionPath = [
      "${config.xdg.dataHome}/npm/bin"
    ];

    # Configure ZSH environment variables for NPM
    programs.zsh = {
      envExtra = ''
        # NPM environment variables
        export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"
      '';
    };

    ###########################################################################
    # Activation Scripts
    ###########################################################################
    # Set up NPM directories
    home.activation.npmSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Set up environment for npm
      export PATH=$PATH:${pkgs.nodejs_20}/bin
      export NPM_CONFIG_PREFIX=${config.xdg.dataHome}/npm
      export NPM_CONFIG_CACHE=${config.xdg.cacheHome}/npm
      export NPM_CONFIG_USERCONFIG=${config.xdg.configHome}/npm/npmrc
      export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"

      # Ensure directories exist with proper permissions
      mkdir -p ${config.xdg.dataHome}/npm
      mkdir -p ${config.xdg.cacheHome}/npm
      mkdir -p ${config.xdg.configHome}/npm/config
      mkdir -p "$XDG_RUNTIME_DIR/npm"
    '';
  };
}
