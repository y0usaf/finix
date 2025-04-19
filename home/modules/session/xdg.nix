###############################################################################
# XDG Configuration Module
# Configures XDG base directories, default applications, and program data paths
# - Base directories setup
# - Default application associations
# - MIME type handling
# - XDG compliance for various programs
###############################################################################
{
  config,
  pkgs,
  lib,
  host,
  ...
}: let
  cfg = config.cfg.core.xdg;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.core.xdg = {
    enable = lib.mkEnableOption "XDG directory configuration";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # XDG Configuration
    ###########################################################################
    xdg = {
      enable = true;

      # Configure base directories
      userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
          XDG_WALLPAPERS_DIR = "${host.cfg.directories.wallpapers.static.path}";
        };
      };

      # Configure mimeapps
      mimeApps = {
        enable = true;
        defaultApplications = {
          # Web Handlers
          "text/html" = ["firefox.desktop"];
          "x-scheme-handler/http" = ["firefox.desktop"];
          "x-scheme-handler/https" = ["firefox.desktop"];
          "x-scheme-handler/ftp" = ["firefox.desktop"];
          "x-scheme-handler/chrome" = ["firefox.desktop"];
          "x-scheme-handler/discord" = ["discord.desktop"];

          # File Types
          "inode/directory" = ["${host.cfg.defaults.fileManager.command}.desktop"];

          # Media Types
          "video/mp4" = ["${host.cfg.defaults.mediaPlayer.command}.desktop"];
          "video/x-matroska" = ["${host.cfg.defaults.mediaPlayer.command}.desktop"];
          "video/webm" = ["${host.cfg.defaults.mediaPlayer.command}.desktop"];

          # Images
          "image/jpeg" = ["${host.cfg.defaults.imageViewer.command}.desktop"];
          "image/png" = ["${host.cfg.defaults.imageViewer.command}.desktop"];
          "image/gif" = ["${host.cfg.defaults.imageViewer.command}.desktop"];
          "image/tiff" = ["${host.cfg.defaults.imageViewer.command}.desktop"];
          "image/bmp" = ["${host.cfg.defaults.imageViewer.command}.desktop"];

          # Archives
          "application/zip" = ["${host.cfg.defaults.archiveManager.command}"];
          "application/x-7z-compressed" = ["${host.cfg.defaults.archiveManager.command}"];
          "application/x-tar" = ["${host.cfg.defaults.archiveManager.command}.desktop"];
          "application/gzip" = ["${host.cfg.defaults.archiveManager.command}.desktop"];
          "application/x-compressed-tar" = ["${host.cfg.defaults.archiveManager.command}.desktop"];

          # Web Extensions
          "application/x-extension-htm" = ["${host.cfg.defaults.browser.command}.desktop"];
          "application/x-extension-html" = ["${host.cfg.defaults.browser.command}.desktop"];
          "application/x-extension-shtml" = ["${host.cfg.defaults.browser.command}.desktop"];
          "application/xhtml+xml" = ["${host.cfg.defaults.browser.command}.desktop"];
          "application/x-extension-xhtml" = ["${host.cfg.defaults.browser.command}.desktop"];
        };
      };

      ###########################################################################
      # Desktop Entries
      ###########################################################################
      desktopEntries = {
        firefox = {
          name = "Firefox";
          genericName = "Web Browser";
          exec = "firefox %U";
          terminal = false;
          categories = ["Application" "Network" "WebBrowser"];
          mimeType = [
            "text/html"
            "text/xml"
            "application/xhtml+xml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
            "x-scheme-handler/ftp"
          ];
        };
      };
    };

    ###########################################################################
    # Environment Variables
    ###########################################################################
    home.sessionVariables = lib.mkMerge [
      {
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
      }
      (lib.mkIf host.cfg.core.nvidia.enable {
        __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";
      })
    ];

    ###########################################################################
    # Activation Scripts
    ###########################################################################
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
  };
}
