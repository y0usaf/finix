#===============================================================================
#                       📁 XDG Configuration 📁
#===============================================================================
# 🗂️ Base directories
# 🎯 Default apps
# 🔧 MIME types
# 📦 Program data
#===============================================================================
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
        # Web Handlers
        "text/html" = ["${globals.defaultBrowser}.desktop"];
        "x-scheme-handler/http" = ["${globals.defaultBrowser}.desktop"];
        "x-scheme-handler/https" = ["${globals.defaultBrowser}.desktop"];
        "x-scheme-handler/discord" = ["${globals.defaultDiscord}.desktop"];

        # File Types
        "inode/directory" = ["${globals.defaultFileManager}.desktop"];

        # Media Types
        "video/mp4" = ["mpv.desktop"];
        "video/x-matroska" = ["mpv.desktop"];
        "video/webm" = ["mpv.desktop"];

        # Images
        "image/jpeg" = ["imv.desktop"];
        "image/png" = ["imv.desktop"];
        "image/gif" = ["imv.desktop"];
        "image/tiff" = ["imv.desktop"];
        "image/bmp" = ["imv.desktop"];

        # Archives
        "application/zip" = ["7zFM.desktop"];
        "application/x-7z-compressed" = ["7zFM.desktop"];
        "application/x-tar" = ["7zFM.desktop"];
        "application/gzip" = ["7zFM.desktop"];
        "application/x-compressed-tar" = ["7zFM.desktop"];
      };
    };
  };

  # Environment variables for programs that need manual XDG compliance
  home.sessionVariables = {
    # Android
    ANDROID_HOME = "${config.xdg.dataHome}/android";
    ADB_VENDOR_KEY = "${config.xdg.configHome}/android";

    # Development Tools
    PYENV_ROOT = "${config.xdg.dataHome}/pyenv";
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_PREFIX = "${config.xdg.dataHome}/npm";
    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    NPM_CONFIG_INIT_MODULE = "${config.xdg.configHome}/npm/config/npm-init.js";
    NUGET_PACKAGES = "${config.xdg.cacheHome}/NuGetPackages";
    KERAS_HOME = "${config.xdg.stateHome}/keras";
    NIMBLE_DIR = "${config.xdg.dataHome}/nimble";
    DOTNET_CLI_HOME = "${config.xdg.dataHome}/dotnet";
    AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    GOPATH = "${config.xdg.dataHome}/go";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=\"${config.xdg.configHome}/java\"";

    # Various tools
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite_history";
    WGET_HSTS_FILE = "${config.xdg.dataHome}/wget-hsts";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python_history";
    HISTFILE = "${config.xdg.stateHome}/zsh/history";
    GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    PARALLEL_HOME = "${config.xdg.configHome}/parallel";

    # Applications
    SPOTDL_CONFIG = "${config.xdg.configHome}/spotdl.yml";
    DVDCSS_CACHE = "${config.xdg.dataHome}/dvdcss";
    WINEPREFIX = "${config.xdg.dataHome}/wine";
    TEXMFVAR = "${config.xdg.cacheHome}/texlive/texmf-var";
    SSB_HOME = "${config.xdg.dataHome}/zoom";

    # NVIDIA
    CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
  };

  # Ensure required directories exist
  home.activation = {
    createXdgDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${config.xdg.cacheHome}/nv
      $DRY_RUN_CMD mkdir -p ${config.xdg.stateHome}/{less,node,sqlite}
      $DRY_RUN_CMD mkdir -p ${config.xdg.configHome}/python
      $DRY_RUN_CMD mkdir -p ${config.xdg.dataHome}/{android,wget}
      $DRY_RUN_CMD mkdir -p ${config.xdg.cacheHome}/{less,npm,NuGetPackages}
      $DRY_RUN_CMD mkdir -p ${config.xdg.configHome}/{npm/config,python,aws,java,parallel}
      $DRY_RUN_CMD mkdir -p ${config.xdg.dataHome}/{npm,android,gnupg,wine,cargo,rustup,go}
      $DRY_RUN_CMD mkdir -p ${config.xdg.stateHome}/{python,keras,zsh}
    '';
  };
}
