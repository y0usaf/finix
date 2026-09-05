{config, ...}: let
  userName = config.user.name;
  home = config.user.homeDirectory;
  xdgConfig = "${home}/.config";
  xdgData = "${home}/.local/share";
  xdgState = "${home}/.local/state";
  xdgCache = "${home}/.cache";
in {
  config = {
    # (sessionVariables re-homed to variables for the compat remap.)
    environment.variables = {
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
      ANDROID_AVD_HOME = "${xdgData}/android/avd";
      # NPM_CONFIG_TMP: deferred to session runtime; XDG_RUNTIME_DIR cannot
      # be expressed in environment.variables (see NOTE at line 60).
      ADB_VENDOR_KEY = "${xdgConfig}/android";

      # --- AWS ---
      # --- Shell history ---
      # bash's readline history (orthogonal to rush's SQLite history store).
      # xdg-ninja report requires HISTFILE; file is created on first write.
      HISTFILE = "${xdgState}/bash/history";
      # --- rush history ---
      # rush stores history in SQLite at $XDG_STATE_HOME/rush/history.sqlite
      # (no HISTFILE). LESSHISTFILE is for less(1).
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

      # --- Node / npm ---
      NODE_REPL_HISTORY = "${xdgState}/node_repl_history";
      NPM_CONFIG_USERCONFIG = "${xdgConfig}/npm/npmrc";
      NPM_CONFIG_CACHE = "${xdgCache}/npm";
      NPM_CONFIG_INIT_MODULE = "${xdgConfig}/npm/config/npm-init.js";

      # --- AI coding agents (no native XDG support) ---
      CLAUDE_CONFIG_DIR = "${xdgConfig}/claude";
      CODEX_HOME = "${xdgConfig}/codex";
      # PI_CODING_AGENT_DIR intentionally unset: pi (native ~/.pi/agent) and
      # omp (native ~/.omp/agent) both resolve the SAME var, so a global value
      # collapses them into one shared agent dir (shared sessions/dbs, schema
      # drift risk). Native paths are impermanence-allowlisted instead.
      # NOTE (unresolved): NPM_CONFIG_TMP is intentionally NOT set here —
      # freezing it to /run/user/<uid> requires a verified UID and deferred
      # expansion that environment.variables cannot express; leave it unset
      # in the interim.
      # NOTE: HISTFILE/ANDROID_AVD_HOME/NPM_CONFIG_TMP were absent from this
      # module. HISTFILE is intentionally absent: rush stores shell history
      # in SQLite at $XDG_STATE_HOME/rush/history.sqlite. ANDROID_AVD_HOME
      # and NPM_CONFIG_TMP remain genuinely missing from the report's list;
      # follow-up required.

      # --- azure / cuda / ipython (env-var re-homing) ---
      AZURE_CONFIG_DIR = "${xdgData}/azure";
      CUDA_CACHE_PATH = "${xdgCache}/nv";
      IPYTHONDIR = "${xdgConfig}/ipython";

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
