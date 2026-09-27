{config, ...}: let
  userName = config.user.name;
  home = config.user.homeDirectory;
  xdgConfig = "${home}/.config";
  xdgData = "${home}/.local/share";
  xdgState = "${home}/.local/state";
  xdgCache = "${home}/.cache";
in {
  config = {
    environment.variables = {
      XDG_CONFIG_HOME = xdgConfig;
      XDG_DATA_HOME = xdgData;
      XDG_STATE_HOME = xdgState;
      XDG_CACHE_HOME = xdgCache;

      XDG_SCREENSHOTS_DIR = "${home}/Pictures/Screenshots";
      XDG_WALLPAPERS_DIR = "${home}/Pictures/Wallpapers";

      ANDROID_USER_HOME = "${xdgData}/android";
      ANDROID_AVD_HOME = "${xdgData}/android/avd";
      ADB_VENDOR_KEY = "${xdgConfig}/android";

      HISTFILE = "${xdgState}/bash/history";
      LESSHISTFILE = "${xdgState}/less/history";
      CARGO_HOME = "${xdgData}/cargo";
      RUSTUP_HOME = "${xdgData}/rustup";
      BUN_INSTALL = "${xdgData}/bun";
      BUNFIG = "${xdgConfig}/bun/bunfig.toml";
      DOTNET_CLI_HOME = "${xdgData}/dotnet";
      GOPATH = "${xdgData}/go";
      NIMBLE_DIR = "${xdgData}/nimble";
      NUGET_PACKAGES = "${xdgCache}/NuGetPackages";
      PYENV_ROOT = "${xdgData}/pyenv";
      _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${xdgConfig}/java";

      NODE_REPL_HISTORY = "${xdgState}/node_repl_history";
      NPM_CONFIG_USERCONFIG = "${home}/.npmrc";
      NPM_CONFIG_PREFIX = "${xdgData}/npm";
      NPM_CONFIG_CACHE = "${xdgCache}/npm";
      NPM_CONFIG_INIT_MODULE = "${xdgConfig}/npm/config/npm-init.js";

      CLAUDE_CONFIG_DIR = "${xdgConfig}/claude";
      CODEX_HOME = "${xdgConfig}/codex";

      AZURE_CONFIG_DIR = "${xdgData}/azure";
      CUDA_CACHE_PATH = "${xdgCache}/nv";
      IPYTHONDIR = "${xdgConfig}/ipython";

      SQLITE_HISTORY = "${xdgState}/sqlite_history";

      GNUPGHOME = "${xdgData}/gnupg";

      DOCKER_CONFIG = "${xdgConfig}/docker";

      GRADLE_USER_HOME = "${xdgData}/gradle";
      PARALLEL_HOME = "${xdgConfig}/parallel";

      DVDCSS_CACHE = "${xdgCache}/dvdcss";
      GTK2_RC_FILES = "${xdgConfig}/gtk-2.0/gtkrc";
      SSB_HOME = "${xdgData}/zoom";
      WINEPREFIX = "${xdgData}/wine";

      __GL_SHADER_DISK_CACHE_PATH = "${xdgCache}/nv";

      TEXMFVAR = "${xdgCache}/texlive/texmf-var";

      KERAS_HOME = "${xdgState}/keras";
    };

    manzil.users."${userName}".files = {
      ".config/user-dirs.dirs" = {
        text = ''
          XDG_DESKTOP_DIR="${home}/Desktop"
          XDG_DOWNLOAD_DIR="${home}/Downloads"
          XDG_TEMPLATES_DIR="${home}/Templates"
          XDG_PUBLICSHARE_DIR="${home}/Public"
          XDG_DOCUMENTS_DIR="${home}/Documents"
          XDG_MUSIC_DIR="${home}/Music"
          XDG_PICTURES_DIR="${home}/Pictures"
          XDG_VIDEOS_DIR="${home}/Videos"
          XDG_SCREENSHOTS_DIR="${home}/Pictures/Screenshots"
          XDG_WALLPAPERS_DIR="${home}/Pictures/Wallpapers"
        '';
      };
    };
  };
}
