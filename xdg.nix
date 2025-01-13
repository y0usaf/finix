{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  xdg = {
    enable = true;

    # Configure base directories
    userDirs = {
      enable = true;
      createDirectories = true;
      extraConfig = {
        XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
        XDG_WALLPAPERS_DIR = "${globals.wallpaperDir}";
      };
    };

    # Configure mimeapps
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = ["${globals.defaultBrowser}.desktop"];
        "x-scheme-handler/http" = ["${globals.defaultBrowser}.desktop"];
        "x-scheme-handler/https" = ["${globals.defaultBrowser}.desktop"];
        "x-scheme-handler/discord" = ["${globals.defaultDiscord}.desktop"];
      };
    };
  };

  # Environment variables for programs that need manual XDG compliance
  home.sessionVariables = {
    # Android
    ANDROID_HOME = "${config.xdg.dataHome}/android";
    ADB_VENDOR_KEY = "${config.xdg.configHome}/android";

    # NVIDIA
    CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";

    # Various tools
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite_history";
    WGET_HSTS_FILE = "${config.xdg.dataHome}/wget-hsts";
  };

  # Ensure required directories exist
  home.activation = {
    createXdgDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${config.xdg.cacheHome}/nv
      $DRY_RUN_CMD mkdir -p ${config.xdg.stateHome}/{less,node,sqlite}
      $DRY_RUN_CMD mkdir -p ${config.xdg.configHome}/python
      $DRY_RUN_CMD mkdir -p ${config.xdg.dataHome}/{android,wget}
    '';
  };
}
