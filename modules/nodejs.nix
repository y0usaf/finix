{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = lib.mkIf (builtins.elem "nodejs" profile.features) {
    home.packages = with pkgs; [
      nodejs_20    # Latest LTS version
      nodePackages.npm
      nodePackages.pnpm
    ];

    # NPM global config
    home.file.".npmrc".text = ''
      prefix=${config.xdg.dataHome}/npm
      cache=${config.xdg.cacheHome}/npm
      init-module=${config.xdg.configHome}/npm/config/npm-init.js
      store-dir=${config.xdg.cacheHome}/pnpm/store
    '';

    # Install global NPM packages
    home.activation.npmPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
      export PATH=$PATH:${pkgs.nodejs_20}/bin
      export NPM_CONFIG_PREFIX=${config.xdg.dataHome}/npm
      export NPM_CONFIG_CACHE=${config.xdg.cacheHome}/npm
      
      # Ensure directories exist
      mkdir -p ${config.xdg.dataHome}/npm
      mkdir -p ${config.xdg.cacheHome}/npm
      
      # Install global packages
      ${pkgs.nodejs_20}/bin/npm install -g @anthropic-ai/claude-code
    '';
  };
} 