#─────────────────────────── 🌍 SYSTEM OPTIONS 🌍 ───────────────────────────#
{lib, ...}: let
  ###############################
  #  Type Definitions & Helpers #
  ###############################
  t = lib.types;
  mkStr = t.str;
  mkBool = t.bool;
  mkListOfStr = t.listOf t.str;
  mkOpt = type: description: lib.mkOption {inherit type description;};
  mkOptDef = type: default: description: lib.mkOption {inherit type default description;};

  ########################
  #  Submodule Options   #
  ########################
  defaultAppModule = t.submodule {
    options = {
      package = mkOpt mkStr "Package name to install";
      command = mkOpt mkStr "Command to execute the application";
    };
  };

  fontModule = t.submodule {
    options = {
      package = mkOpt (t.listOf mkStr) "Font package attribute path";
      name = mkOpt mkStr "Font name as it appears to the system";
    };
  };

  ###############################
  #    Valid Features List      #
  ###############################
  validFeatures = [
    "hyprland"
    "ags"
    "wayland"
    "nvidia"
    "gaming"
    "media"
    "creative"
    "virtualization"
    "backup"
    "neovim"
    "android"
    "webapps"
    "vscode"
    "wallust"
  ];

  ###########################################
  #   Package Sets Grouped by Feature       #
  ###########################################
  packageSets = {
    core = [
      "git"
      "curl"
      "wget"
      "cachix"
      "unzip"
      "bash"
      "vim"
      "dconf"
      "lsd"
      "alejandra"
      "lm_sensors"
      "syncthing"
    ];
    wayland = [
      "grim"
      "slurp"
      "wl-clipboard"
      "hyprpicker"
    ];
    media = [
      "pavucontrol"
      "ffmpeg"
      "yt-dlp-light"
      "vlc"
      "stremio"
      "cmus"
    ];
    creative = [
      "cmake"
      "meson"
      "bottom"
      "cpio"
      "pkg-config"
      "ninja"
      "gcc"
      "python3"
    ];
  };

  ###########################################
  #   Validation: Package Sets vs Features  #
  ###########################################
  invalidSets = builtins.filter (
    setName:
      setName != "core" && !(builtins.elem setName validFeatures)
  ) (builtins.attrNames packageSets);

  _ =
    lib.assertMsg (invalidSets == [])
    "Found package sets without corresponding features: ${builtins.toString invalidSets}";

  dummy = null; # Add a dummy attribute to ensure proper structure
in {
  ########################################
  #          Core System Options         #
  ########################################
  username = mkOpt mkStr "The username for the system.";
  hostname = mkOpt mkStr "The system hostname.";
  homeDirectory = mkOpt mkStr "The path to the user's home directory.";
  stateVersion = mkOpt mkStr "The system state version.";
  timezone = mkOpt mkStr "The system timezone.";

  ########################################
  #      Package Management Options      #
  ########################################
  corePackages = mkOptDef mkListOfStr packageSets.core "Essential packages that will always be installed";
  packageSets = mkOptDef (t.attrsOf (t.listOf t.str)) packageSets "Package sets organized by feature";
  features = mkOptDef (t.listOf (t.enum validFeatures)) [] "List of enabled features";

  ########################################
  #         System Appearance            #
  ########################################
  mainFont = mkOpt fontModule "Primary system font configuration";
  fallbackFonts = mkOptDef (t.listOf fontModule) [] "List of fallback fonts in order of preference";
  baseFontSize = mkOptDef t.int 12 "Base font size that other UI elements should scale from";
  cursorSize = mkOptDef t.int 24 "Size of the system cursor";
  dpi = mkOptDef t.int 96 "Display DPI setting for the system";

  ########################################
  #       Default Applications           #
  ########################################
  defaultBrowser = mkOpt defaultAppModule "Default web browser configuration.";
  defaultEditor = mkOpt defaultAppModule "Default text editor configuration.";
  defaultIde = mkOpt defaultAppModule "Default IDE configuration.";
  defaultTerminal = mkOpt defaultAppModule "Default terminal emulator configuration.";
  defaultFileManager = mkOpt defaultAppModule "Default file manager configuration.";
  defaultLauncher = mkOpt defaultAppModule "Default application launcher configuration.";
  defaultDiscord = mkOpt defaultAppModule "Default Discord client configuration.";
  defaultArchiveManager = mkOpt defaultAppModule "Default archive manager configuration.";
  defaultImageViewer = mkOpt defaultAppModule "Default image viewer configuration.";
  defaultMediaPlayer = mkOpt defaultAppModule "Default media player configuration.";

  ########################################
  #         Directory Configurations     #
  ########################################
  flakeDir = mkOpt mkStr "The directory where the flake lives.";
  musicDir = mkOpt mkStr "Directory for music files.";
  dcimDir = mkOpt mkStr "Directory for pictures (DCIM).";
  steamDir = mkOpt mkStr "Directory for Steam.";
  wallpaperDir = mkOpt mkStr "Wallpaper directory.";
  wallpaperVideoDir = mkOpt mkStr "Wallpaper video directory.";

  ########################################
  #          Git Configurations          #
  ########################################
  gitName = mkOpt mkStr "Git username.";
  gitEmail = mkOpt mkStr "Git email address.";
  gitHomeManagerRepo = mkOpt mkStr "URL of the Home Manager repository.";
}
