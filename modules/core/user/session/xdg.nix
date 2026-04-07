{config, ...}: let
  userName = config.user.name;
  home = config.user.homeDirectory;
  xdgConfig = "${home}/.config";
  xdgData = "${home}/.local/share";
  xdgState = "${home}/.local/state";
  xdgCache = "${home}/.cache";
in {
  config = {
    environment.sessionVariables = {
      # --- XDG base directories ---
      XDG_CONFIG_HOME = xdgConfig;
      XDG_DATA_HOME = xdgData;
      XDG_STATE_HOME = xdgState;
      XDG_CACHE_HOME = xdgCache;

      # --- Custom user directories ---
      XDG_SCREENSHOTS_DIR = "${home}/Pictures/Screenshots";
      XDG_WALLPAPERS_DIR = "${home}/Pictures/Wallpapers";

      # --- Android ---
      ANDROID_USER_HOME = "${xdgData}/android";
      ADB_VENDOR_KEY = "${xdgConfig}/android";

      # --- AWS ---
      AWS_CONFIG_FILE = "${xdgConfig}/aws/config";
      AWS_SHARED_CREDENTIALS_FILE = "${xdgConfig}/aws/credentials";

      # --- Shell history ---
      HISTFILE = "${xdgState}/bash/history";
      LESSHISTFILE = "${xdgState}/less/history";

      # --- Language runtimes ---
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

      # --- Node / npm ---
      NODE_REPL_HISTORY = "${xdgState}/node_repl_history";
      NPM_CONFIG_USERCONFIG = "${xdgConfig}/npm/npmrc";
      NPM_CONFIG_CACHE = "${xdgCache}/npm";
      NPM_CONFIG_INIT_MODULE = "${xdgConfig}/npm/config/npm-init.js";

      # --- Databases / REPLs ---
      SQLITE_HISTORY = "${xdgState}/sqlite_history";

      # --- Security / crypto ---
      GNUPGHOME = "${xdgData}/gnupg";

      # --- Docker ---
      DOCKER_CONFIG = "${xdgConfig}/docker";

      # --- Build tools ---
      GRADLE_USER_HOME = "${xdgData}/gradle";
      PARALLEL_HOME = "${xdgConfig}/parallel";

      # --- Media / desktop ---
      DVDCSS_CACHE = "${xdgCache}/dvdcss";
      GTK2_RC_FILES = "${xdgConfig}/gtk-2.0/gtkrc";
      SSB_HOME = "${xdgData}/zoom";
      WINEPREFIX = "${xdgData}/wine";

      # --- GPU / graphics ---
      __GL_SHADER_DISK_CACHE_PATH = "${xdgCache}/nv";

      # --- TeX ---
      TEXMFVAR = "${xdgCache}/texlive/texmf-var";

      # --- Misc ---
      KERAS_HOME = "${xdgState}/keras";
      # WGET_HSTS_FILE: wget does not read env vars; XDG compliance via alias in shell configs
    };

    # Ensure critical XDG directories exist
    systemd.tmpfiles.rules = [
      "d ${xdgConfig} 0755 ${userName} ${userName} - -"
      "d ${xdgData} 0755 ${userName} ${userName} - -"
      "d ${xdgState} 0755 ${userName} ${userName} - -"
      "d ${xdgCache} 0700 ${userName} ${userName} - -"
      "d ${xdgState}/bash 0755 ${userName} ${userName} - -"
      "d ${xdgState}/less 0755 ${userName} ${userName} - -"
      "d ${xdgState}/zsh 0755 ${userName} ${userName} - -"
    ];

    bayt.users."${userName}".files = {
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
