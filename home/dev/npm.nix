###############################################################################
# Node.js & NPM Configuration (Maid Version)
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
  cfg = config.home.programs.dev.npm;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.programs.dev.npm = {
    enable = lib.mkEnableOption "Node.js and NPM configuration";
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
        nodejs_20
      ];

      ###########################################################################
      # Configuration Files
      ###########################################################################
      file = {
        # NPM global config - use XDG directories
        xdg_config.".config/npm/npmrc".text = ''
          prefix=$HOME/.local/share/npm
          cache={{xdg_cache_home}}/npm
          init-module=$HOME/.config/npm/config/npm-init.js
          store-dir={{xdg_cache_home}}/pnpm/store
        '';

        # NPM setup script
        home.".local/share/bin/npm-setup" = {
          text = ''
            #!/bin/bash
            # Set up NPM directories
            mkdir -p $HOME/.local/share/npm
            mkdir -p {{xdg_cache_home}}/npm
            mkdir -p $HOME/.config/npm/config
            mkdir -p {{xdg_cache_home}}/pnpm/store
            mkdir -p "$XDG_RUNTIME_DIR/npm"
          '';
          executable = true;
        };
      };

      ###########################################################################
      # Directory Setup via tmpfiles
      ###########################################################################
      systemd.tmpfiles.dynamicRules = [
        "d {{home}}/.local/share/npm 0755 {{user}} {{group}} - -"
        "d {{xdg_cache_home}}/npm 0755 {{user}} {{group}} - -"
        "d {{home}}/.config/npm/config 0755 {{user}} {{group}} - -"
        "d {{xdg_cache_home}}/pnpm/store 0755 {{user}} {{group}} - -"
        "d {{xdg_runtime_dir}}/npm 0755 {{user}} {{group}} - -"
      ];
    };
  };
}
