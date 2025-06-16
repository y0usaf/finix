###############################################################################
# XDG Configuration (Maid Version)
# Configures XDG base directories, default applications, and program data paths
# - Base directories setup
# - Default application associations
# - MIME type handling
# - XDG compliance for various programs
###############################################################################
{
  config,
  lib,
  ...
}: let
  cfg = config.cfg.home.session.xdg;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.session.xdg = {
    enable = lib.mkEnableOption "XDG directory configuration";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      ###########################################################################
      # File Configuration
      ###########################################################################
      file = {
        ###########################################################################
        # Environment Variables in .zshenv
        ###########################################################################
        home.".zshenv".text = lib.mkAfter ''
          # XDG Base Directories
          export XDG_CONFIG_HOME="$HOME/.config"
          export XDG_DATA_HOME="$HOME/.local/share"
          export XDG_STATE_HOME="$HOME/.local/state"
          export XDG_CACHE_HOME="$HOME/.cache"

          # XDG User Directories
          export XDG_SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
          export XDG_WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"

          # Android
          export ANDROID_HOME="$XDG_DATA_HOME/android"
          export ADB_VENDOR_KEY="$XDG_CONFIG_HOME/android"

          # Development Tools
          export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
          export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
          export NPM_CONFIG_PREFIX="$XDG_DATA_HOME/npm"
          export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
          export NPM_CONFIG_INIT_MODULE="$XDG_CONFIG_HOME/npm/config/npm-init.js"
          export NUGET_PACKAGES="$XDG_CACHE_HOME/NuGetPackages"
          export KERAS_HOME="$XDG_STATE_HOME/keras"
          export NIMBLE_DIR="$XDG_DATA_HOME/nimble"
          export DOTNET_CLI_HOME="$XDG_DATA_HOME/dotnet"
          export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"
          export CARGO_HOME="$XDG_DATA_HOME/cargo"
          export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
          export GOPATH="$XDG_DATA_HOME/go"
          export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=\"$XDG_CONFIG_HOME/java\""

          # Various tools
          export LESSHISTFILE="$XDG_STATE_HOME/less/history"
          export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"
          export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
          export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite_history"
          export WGET_HSTS_FILE="$XDG_DATA_HOME/wget-hsts"
          export PYTHON_HISTORY="$XDG_STATE_HOME/python_history"
          export HISTFILE="$XDG_STATE_HOME/zsh/history"
          export GNUPGHOME="$XDG_DATA_HOME/gnupg"
          export PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"

          # Applications
          export SPOTDL_CONFIG="$XDG_CONFIG_HOME/spotdl.yml"
          export DVDCSS_CACHE="$XDG_DATA_HOME/dvdcss"
          export WINEPREFIX="$XDG_DATA_HOME/wine"
          export TEXMFVAR="$XDG_CACHE_HOME/texlive/texmf-var"
          export SSB_HOME="$XDG_DATA_HOME/zoom"

          # NVIDIA (conditional - always export for simplicity)
          export __GL_SHADER_DISK_CACHE_PATH="$XDG_CACHE_HOME/nv"
        '';

        ###########################################################################
        # XDG Configuration Files
        ###########################################################################
        xdg_config = {
          # XDG User Directories Configuration
          "user-dirs.dirs".text = ''
            XDG_DESKTOP_DIR="$HOME/Desktop"
            XDG_DOWNLOAD_DIR="$HOME/Downloads"
            XDG_TEMPLATES_DIR="$HOME/Templates"
            XDG_PUBLICSHARE_DIR="$HOME/Public"
            XDG_DOCUMENTS_DIR="$HOME/Documents"
            XDG_MUSIC_DIR="$HOME/Music"
            XDG_PICTURES_DIR="$HOME/Pictures"
            XDG_VIDEOS_DIR="$HOME/Videos"
            XDG_SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
            XDG_WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
          '';

          # MIME Applications Configuration
          "mimeapps.list".text = ''
            [Default Applications]
            # Web Handlers
            text/html=firefox.desktop
            x-scheme-handler/http=firefox.desktop
            x-scheme-handler/https=firefox.desktop
            x-scheme-handler/ftp=firefox.desktop
            x-scheme-handler/chrome=firefox.desktop
            x-scheme-handler/discord=discord.desktop

            # File Types
            inode/directory=pcmanfm.desktop

            # Media Types
            video/mp4=mpv.desktop
            video/x-matroska=mpv.desktop
            video/webm=mpv.desktop

            # Images
            image/jpeg=imv.desktop
            image/png=imv.desktop
            image/gif=imv.desktop
            image/tiff=imv.desktop
            image/bmp=imv.desktop

            # Archives
            application/zip=file-roller.desktop
            application/x-7z-compressed=file-roller.desktop
            application/x-tar=file-roller.desktop
            application/gzip=file-roller.desktop
            application/x-compressed-tar=file-roller.desktop

            # Web Extensions
            application/x-extension-htm=firefox.desktop
            application/x-extension-html=firefox.desktop
            application/x-extension-shtml=firefox.desktop
            application/xhtml+xml=firefox.desktop
            application/x-extension-xhtml=firefox.desktop

            [Added Associations]
            text/html=firefox.desktop
            x-scheme-handler/http=firefox.desktop
            x-scheme-handler/https=firefox.desktop
            x-scheme-handler/ftp=firefox.desktop
          '';

        ###########################################################################
        # Desktop Entries
        ###########################################################################
        xdg_data."applications/firefox.desktop".text = ''
          [Desktop Entry]
          Name=Firefox
          GenericName=Web Browser
          Exec=firefox %U
          Terminal=false
          Type=Application
          Categories=Application;Network;WebBrowser;
          MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;
          Icon=firefox
          StartupNotify=true
        '';

          # Python RC Configuration
          "python/pythonrc".text = ''
            import os
            import atexit
            import readline

            # Set up history file
            histfile = os.path.join(os.path.expanduser("~/.local/state"), "python_history")
            try:
                readline.read_history_file(histfile)
                h_len = readline.get_current_history_length()
            except FileNotFoundError:
                open(histfile, 'wb').close()
                h_len = 0

            def save(prev_h_len, histfile):
                new_h_len = readline.get_current_history_length()
                readline.set_history_length(1000)
                readline.append_history_file(new_h_len - prev_h_len, histfile)

            atexit.register(save, h_len, histfile)
          '';
        };
      };
    };
  };
}
