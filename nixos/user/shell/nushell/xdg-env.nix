{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.user.shell.nushell.enable {
    usr.files = {
      ".config/nushell/env.nu" = {
        clobber = true;
        text = lib.mkAfter ''
          # XDG Base Directory Specification
          $env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
          $env.XDG_DATA_HOME = ($env.HOME | path join ".local/share")
          $env.XDG_STATE_HOME = ($env.HOME | path join ".local/state")
          $env.XDG_CACHE_HOME = ($env.HOME | path join ".cache")

          # Custom XDG directories for desktop integration
          $env.XDG_SCREENSHOTS_DIR = ($env.HOME | path join "Pictures/Screenshots")
          $env.XDG_WALLPAPERS_DIR = ($env.HOME | path join "Pictures/Wallpapers")

          # Application XDG compliance - Environment Variables
          $env.ANDROID_HOME = ($env.XDG_DATA_HOME | path join "android")
          $env.ADB_VENDOR_KEY = ($env.XDG_CONFIG_HOME | path join "android")
          $env.PYENV_ROOT = ($env.XDG_DATA_HOME | path join "pyenv")
          $env.NPM_CONFIG_USERCONFIG = ($env.XDG_CONFIG_HOME | path join "npm/npmrc")
          $env.NPM_CONFIG_PREFIX = ($env.XDG_DATA_HOME | path join "npm")
          $env.NPM_CONFIG_CACHE = ($env.XDG_CACHE_HOME | path join "npm")
          $env.NPM_CONFIG_INIT_MODULE = ($env.XDG_CONFIG_HOME | path join "npm/config/npm-init.js")
          $env.NPM_CONFIG_TMP = ($env.XDG_RUNTIME_DIR | path join "npm")
          $env.NUGET_PACKAGES = ($env.XDG_CACHE_HOME | path join "NuGetPackages")
          $env.KERAS_HOME = ($env.XDG_STATE_HOME | path join "keras")
          $env.NIMBLE_DIR = ($env.XDG_DATA_HOME | path join "nimble")
          $env.DOTNET_CLI_HOME = ($env.XDG_DATA_HOME | path join "dotnet")
          $env.AWS_SHARED_CREDENTIALS_FILE = ($env.XDG_CONFIG_HOME | path join "aws/credentials")
          $env.CARGO_HOME = ($env.XDG_DATA_HOME | path join "cargo")
          $env.RUSTUP_HOME = ($env.XDG_DATA_HOME | path join "rustup")
          $env.GOPATH = ($env.XDG_DATA_HOME | path join "go")
          $env._JAVA_OPTIONS = "-Djava.util.prefs.userRoot=\"($env.XDG_CONFIG_HOME | path join 'java')\""
          $env.LESSHISTFILE = ($env.XDG_STATE_HOME | path join "less/history")
          $env.NODE_REPL_HISTORY = ($env.XDG_STATE_HOME | path join "node_repl_history")
          $env.PYTHONSTARTUP = ($env.XDG_CONFIG_HOME | path join "python/pythonrc")
          $env.SQLITE_HISTORY = ($env.XDG_STATE_HOME | path join "sqlite_history")
          $env.WGET_HSTS_FILE = ($env.XDG_DATA_HOME | path join "wget-hsts")
          $env.PYTHON_HISTORY = ($env.XDG_STATE_HOME | path join "python_history")
          $env.HISTFILE = ($env.XDG_STATE_HOME | path join "zsh/history")
          $env.GNUPGHOME = ($env.XDG_DATA_HOME | path join "gnupg")
          $env.PARALLEL_HOME = ($env.XDG_CONFIG_HOME | path join "parallel")
          $env.SPOTDL_CONFIG = ($env.XDG_CONFIG_HOME | path join "spotdl.yml")
          $env.DVDCSS_CACHE = ($env.XDG_DATA_HOME | path join "dvdcss")
          $env.WINEPREFIX = ($env.XDG_DATA_HOME | path join "wine")
          $env.TEXMFVAR = ($env.XDG_CACHE_HOME | path join "texlive/texmf-var")
          $env.SSB_HOME = ($env.XDG_DATA_HOME | path join "zoom")
          $env.__GL_SHADER_DISK_CACHE_PATH = ($env.XDG_CACHE_HOME | path join "nv")
          $env.DOCKER_CONFIG = ($env.XDG_CONFIG_HOME | path join "docker")
          $env.CUDA_CACHE_PATH = ($env.XDG_CACHE_HOME | path join "nv")
          $env.GRADLE_USER_HOME = ($env.XDG_DATA_HOME | path join "gradle")
          $env.GTK2_RC_FILES = ($env.XDG_CONFIG_HOME | path join "gtk-2.0/gtkrc")
        '';
      };

      ".config/nushell/aliases/xdg-compliance.nu" = {
        text = ''
          # XDG Base Directory compliance aliases for apps that don't respect env vars

          # wget - Force XDG compliance (additional layer beyond WGET_HSTS_FILE env var)
          alias wget = ^wget --hsts-file=($env.XDG_DATA_HOME | path join "wget-hsts")

          # nvidia-settings - Use XDG config directory (no env var support)
          alias nvidia-settings = ^nvidia-settings --config=($env.XDG_CONFIG_HOME | path join "nvidia/settings")

          # Function to create XDG directories if they don't exist
          def ensure_xdg_dirs [] {
              mkdir ($env.XDG_CONFIG_HOME)
              mkdir ($env.XDG_DATA_HOME)
              mkdir ($env.XDG_STATE_HOME)
              mkdir ($env.XDG_CACHE_HOME)
          }

          # Run on shell startup
          ensure_xdg_dirs
        '';
      };
    };
  };
}
