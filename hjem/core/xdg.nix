###############################################################################
# XDG Base Directory Utilities for Hjem
# Provides helper functions for managing XDG-compliant paths
###############################################################################
_: {
  # Provide XDG path helpers as module arguments
  config._module.args = {
    xdg = rec {
      # XDG Base Directory paths
      configHome = ".config";
      dataHome = ".local/share";
      cacheHome = ".cache";
      stateHome = ".local/state";

      # Helper functions for file paths
      configFile = path: "${configHome}/${path}";
      dataFile = path: "${dataHome}/${path}";
      cacheFile = path: "${cacheHome}/${path}";
      stateFile = path: "${stateHome}/${path}";

      # Helper functions for directories
      configDir = app: "${configHome}/${app}";
      dataDir = app: "${dataHome}/${app}";
      cacheDir = app: "${cacheHome}/${app}";
      stateDir = app: "${stateHome}/${app}";
    };
  };
}
