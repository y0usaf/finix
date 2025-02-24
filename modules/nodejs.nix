{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = lib.mkIf (builtins.elem "nodejs" profile.features) {
    home.packages = with pkgs; [
      # Use nodejs without adding npm/pnpm to avoid collisions
      # with existing nodejs installations
      nodejs_20
    ];

    # NPM global config - use XDG directories
    xdg.configFile."npm/npmrc".text = ''
      prefix=${config.xdg.dataHome}/npm
      cache=${config.xdg.cacheHome}/npm
      init-module=${config.xdg.configHome}/npm/config/npm-init.js
      store-dir=${config.xdg.cacheHome}/pnpm/store
    '';

    # Add npm bin directory to PATH
    home.sessionPath = [
      "${config.xdg.dataHome}/npm/bin"
    ];

    # Install global NPM packages
    home.activation.npmPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Set up environment for npm
      export PATH=$PATH:${pkgs.nodejs_20}/bin
      export NPM_CONFIG_PREFIX=${config.xdg.dataHome}/npm
      export NPM_CONFIG_CACHE=${config.xdg.cacheHome}/npm
      export NPM_CONFIG_USERCONFIG=${config.xdg.configHome}/npm/npmrc
      
      # Ensure directories exist with proper permissions
      mkdir -p ${config.xdg.dataHome}/npm
      mkdir -p ${config.xdg.cacheHome}/npm
      mkdir -p ${config.xdg.configHome}/npm/config
      
      # Force reinstall claude-code package
      echo "Installing @anthropic-ai/claude-code..."
      ${pkgs.nodejs_20}/bin/npm install -g @anthropic-ai/claude-code --force
      
      # Verify installation
      if [ -d "${config.xdg.dataHome}/npm/lib/node_modules/@anthropic-ai/claude-code" ]; then
        echo "✅ @anthropic-ai/claude-code installed successfully"
      else
        echo "❌ Failed to install @anthropic-ai/claude-code"
        # Show npm error logs
        cat ${config.xdg.cacheHome}/npm/_logs/$(ls -t ${config.xdg.cacheHome}/npm/_logs | head -1) || echo "No npm logs found"
      fi
    '';
  };
} 