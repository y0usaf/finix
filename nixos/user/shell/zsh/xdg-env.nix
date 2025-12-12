{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.user.shell.zsh.enable {
    usr.files = {
      ".config/zsh/.zshenv" = {
        clobber = true;
        text = ''
          export XDG_CONFIG_HOME="$HOME/.config"
          export XDG_DATA_HOME="$HOME/.local/share"
          export XDG_STATE_HOME="$HOME/.local/state"
          export XDG_CACHE_HOME="$HOME/.cache"

          export XDG_SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
          export XDG_WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"

          export ANDROID_HOME="$XDG_DATA_HOME/android"
          export ADB_VENDOR_KEY="$XDG_CONFIG_HOME/android"
          export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
          export BUN_INSTALL="$XDG_DATA_HOME/bun"
          export BUNFIG="$XDG_CONFIG_HOME/bun/bunfig.toml"
          export NUGET_PACKAGES="$XDG_CACHE_HOME/NuGetPackages"
          export KERAS_HOME="$XDG_STATE_HOME/keras"
          export NIMBLE_DIR="$XDG_DATA_HOME/nimble"
          export DOTNET_CLI_HOME="$XDG_DATA_HOME/dotnet"
          export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"
          export CARGO_HOME="$XDG_DATA_HOME/cargo"
          export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
          export GOPATH="$XDG_DATA_HOME/go"
          export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=\"$XDG_CONFIG_HOME/java\""
          export LESSHISTFILE="$XDG_STATE_HOME/less/history"
          export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"
          export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
          export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite_history"
          export WGET_HSTS_FILE="$XDG_DATA_HOME/wget-hsts"
          export PYTHON_HISTORY="$XDG_STATE_HOME/python_history"
          export HISTFILE="$XDG_STATE_HOME/zsh/history"
          export GNUPGHOME="$XDG_DATA_HOME/gnupg"
          export PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"
          export SPOTDL_CONFIG="$XDG_CONFIG_HOME/spotdl.yml"
          export DVDCSS_CACHE="$XDG_DATA_HOME/dvdcss"
          export WINEPREFIX="$XDG_DATA_HOME/wine"
          export TEXMFVAR="$XDG_CACHE_HOME/texlive/texmf-var"
          export SSB_HOME="$XDG_DATA_HOME/zoom"
          export __GL_SHADER_DISK_CACHE_PATH="$XDG_CACHE_HOME/nv"
          export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
          export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
          export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
          export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
          export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
          export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
          export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"
          export NPM_CONFIG_INIT_MODULE="$XDG_CONFIG_HOME/npm/config/npm-init.js"
        '';
      };

      ".config/zsh/aliases/xdg-compliance.zsh" = {
        text = ''
          alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'

          alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'

          [[ -d "$XDG_RUNTIME_DIR" ]] && mkdir -p "$XDG_RUNTIME_DIR/bun" 2>/dev/null

          ensure_xdg_dirs() {
              mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
          }

          ensure_xdg_dirs
        '';
      };

      ".config/python/pythonrc" = {
        clobber = true;
        text = ''
          import os
          import atexit
          import readline
          histfile = os.path.join(os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")), "python_history")
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
}
