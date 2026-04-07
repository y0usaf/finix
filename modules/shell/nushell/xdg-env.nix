{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.user.shell.nushell.enable {
    bayt.users."${config.user.name}".files = {
      ".config/nushell/env.nu" = {
        text = ''
          $env.XDG_CONFIG_HOME = $"($env.HOME)/.config"
          $env.XDG_DATA_HOME = $"($env.HOME)/.local/share"
          $env.XDG_STATE_HOME = $"($env.HOME)/.local/state"
          $env.XDG_CACHE_HOME = $"($env.HOME)/.cache"

          $env.XDG_SCREENSHOTS_DIR = $"($env.HOME)/Pictures/Screenshots"
          $env.XDG_WALLPAPERS_DIR = $"($env.HOME)/Pictures/Wallpapers"

          $env.ANDROID_HOME = $"($env.XDG_DATA_HOME)/android"
          $env.ADB_VENDOR_KEY = $"($env.XDG_CONFIG_HOME)/android"
          $env.PYENV_ROOT = $"($env.XDG_DATA_HOME)/pyenv"
          $env.BUN_INSTALL = $"($env.XDG_DATA_HOME)/bun"
          $env.BUNFIG = $"($env.XDG_CONFIG_HOME)/bun/bunfig.toml"
          $env.NUGET_PACKAGES = $"($env.XDG_CACHE_HOME)/NuGetPackages"
          $env.KERAS_HOME = $"($env.XDG_STATE_HOME)/keras"
          $env.NIMBLE_DIR = $"($env.XDG_DATA_HOME)/nimble"
          $env.DOTNET_CLI_HOME = $"($env.XDG_DATA_HOME)/dotnet"
          $env.AWS_SHARED_CREDENTIALS_FILE = $"($env.XDG_CONFIG_HOME)/aws/credentials"
          $env.CARGO_HOME = $"($env.XDG_DATA_HOME)/cargo"
          $env.RUSTUP_HOME = $"($env.XDG_DATA_HOME)/rustup"
          $env.GOPATH = $"($env.XDG_DATA_HOME)/go"
          $env._JAVA_OPTIONS = $"-Djava.util.prefs.userRoot=\"($env.XDG_CONFIG_HOME)/java\""
          $env.LESSHISTFILE = $"($env.XDG_STATE_HOME)/less/history"
          $env.NODE_REPL_HISTORY = $"($env.XDG_STATE_HOME)/node_repl_history"
          $env.PYTHONSTARTUP = $"($env.XDG_CONFIG_HOME)/python/pythonrc"
          $env.SQLITE_HISTORY = $"($env.XDG_STATE_HOME)/sqlite_history"
          $env.WGET_HSTS_FILE = $"($env.XDG_DATA_HOME)/wget-hsts"
          $env.PYTHON_HISTORY = $"($env.XDG_STATE_HOME)/python_history"
          $env.GNUPGHOME = $"($env.XDG_DATA_HOME)/gnupg"
          $env.PARALLEL_HOME = $"($env.XDG_CONFIG_HOME)/parallel"

          $env.DVDCSS_CACHE = $"($env.XDG_DATA_HOME)/dvdcss"
          $env.WINEPREFIX = $"($env.XDG_DATA_HOME)/wine"
          $env.TEXMFVAR = $"($env.XDG_CACHE_HOME)/texlive/texmf-var"
          $env.SSB_HOME = $"($env.XDG_DATA_HOME)/zoom"
          $env.__GL_SHADER_DISK_CACHE_PATH = $"($env.XDG_CACHE_HOME)/nv"
          $env.DOCKER_CONFIG = $"($env.XDG_CONFIG_HOME)/docker"
          $env.CUDA_CACHE_PATH = $"($env.XDG_CACHE_HOME)/nv"
          $env.GRADLE_USER_HOME = $"($env.XDG_DATA_HOME)/gradle"
          $env.GTK2_RC_FILES = $"($env.XDG_CONFIG_HOME)/gtk-2.0/gtkrc"
          $env.NPM_CONFIG_USERCONFIG = $"($env.XDG_CONFIG_HOME)/npm/npmrc"
          $env.NPM_CONFIG_CACHE = $"($env.XDG_CACHE_HOME)/npm"
          $env.NPM_CONFIG_TMP = $"($env.XDG_RUNTIME_DIR? | default '/tmp')/npm"
          $env.NPM_CONFIG_INIT_MODULE = $"($env.XDG_CONFIG_HOME)/npm/config/npm-init.js"

          # Ensure XDG directories exist
          [$env.XDG_CONFIG_HOME $env.XDG_DATA_HOME $env.XDG_STATE_HOME $env.XDG_CACHE_HOME] | each { |d| mkdir $d }

          # Ensure bun runtime dir exists
          let runtime_dir = ($env.XDG_RUNTIME_DIR? | default null)
          if $runtime_dir != null { mkdir $"($runtime_dir)/bun" }
        '';
      };
    };
  };
}
