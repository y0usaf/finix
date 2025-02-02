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
  profile,
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
        XDG_WALLPAPERS_DIR = "${profile.wallpaperDir}";
      };
    };

    # Configure mimeapps
    mimeApps = {
      enable = true;
      defaultApplications = {
        # Web Handlers
        "text/html" = ["${profile.defaultBrowser}.desktop"];
        "x-scheme-handler/http" = ["${profile.defaultBrowser}.desktop"];
        "x-scheme-handler/https" = ["${profile.defaultBrowser}.desktop"];
        "x-scheme-handler/discord" = ["${profile.defaultDiscord}.desktop"];
        "x-scheme-handler/ftp" = ["${profile.defaultBrowser}.desktop"];
        "x-scheme-handler/chrome" = ["${profile.defaultBrowser}.desktop"];

        # File Types
        "inode/directory" = ["${profile.defaultFileManager}.desktop"];

        # Media Types
        "video/mp4" = ["${profile.defaultMediaPlayer}.desktop"];
        "video/x-matroska" = ["${profile.defaultMediaPlayer}.desktop"];
        "video/webm" = ["${profile.defaultMediaPlayer}.desktop"];

        # Images
        "image/jpeg" = ["${profile.defaultImageViewer}.desktop"];
        "image/png" = ["${profile.defaultImageViewer}.desktop"];
        "image/gif" = ["${profile.defaultImageViewer}.desktop"];
        "image/tiff" = ["${profile.defaultImageViewer}.desktop"];
        "image/bmp" = ["${profile.defaultImageViewer}.desktop"];

        # Archives
        "application/zip" = ["${profile.defaultArchiveManager}.desktop"];
        "application/x-7z-compressed" = ["${profile.defaultArchiveManager}.desktop"];
        "application/x-tar" = ["${profile.defaultArchiveManager}.desktop"];
        "application/gzip" = ["${profile.defaultArchiveManager}.desktop"];
        "application/x-compressed-tar" = ["${profile.defaultArchiveManager}.desktop"];

        # Web Extensions
        "application/x-extension-htm" = ["${profile.defaultBrowser}.desktop"];
        "application/x-extension-html" = ["${profile.defaultBrowser}.desktop"];
        "application/x-extension-shtml" = ["${profile.defaultBrowser}.desktop"];
        "application/xhtml+xml" = ["${profile.defaultBrowser}.desktop"];
        "application/x-extension-xhtml" = ["${profile.defaultBrowser}.desktop"];
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
    GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    PARALLEL_HOME = "${config.xdg.configHome}/parallel";

    # Applications
    SPOTDL_CONFIG = "${config.xdg.configHome}/spotdl.yml";
    DVDCSS_CACHE = "${config.xdg.dataHome}/dvdcss";
    WINEPREFIX = "${config.xdg.dataHome}/wine";
    TEXMFVAR = "${config.xdg.cacheHome}/texlive/texmf-var";
    SSB_HOME = "${config.xdg.dataHome}/zoom";

    # NVIDIA
    CUDA_CACHE_PATH = lib.mkIf profile.enableNvidia "${config.xdg.cacheHome}/nv";
    __GL_SHADER_DISK_CACHE_PATH = lib.mkIf profile.enableNvidia "${config.xdg.cacheHome}/nv";
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
