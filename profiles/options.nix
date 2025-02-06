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
      package = mkOptDef mkStr null "Package name to install";
      command = mkOptDef mkStr null "Command to execute the application. Defaults to package name if null";
    };
  };

  # Add a helper for directory paths
  dirModule = t.submodule {
    options = {
      path = mkOpt mkStr "Absolute path to the directory";
      create = mkOptDef mkBool true "Whether to create the directory if it doesn't exist";
    };
  };

  ###############################
  #    Valid Features List      #
  ###############################
  validFeatures = [
    # Development
    "python"
    "neovim"
    "vscode"

    # Desktop Environment
    "hyprland"
    "ags"
    "wayland"
    "wallust"

    # Hardware Support
    "nvidia"
    "android"

    # Use Cases
    "gaming"
    "media"
    "creative"
    "virtualization"
    "backup"
    "webapps"
    "syncthing"
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
      "bottom"
      "tree"
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
    python = [
      "python3"
    ];
    hyprland = [
      "hyprwayland-scanner"
    ];
    syncthing = [
      "syncthing"
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
  mainFont = mkOpt (t.submodule {
    options = {
      packages = mkOpt (t.listOf mkStr) "List of package names for the main fonts";
      names = mkOpt (t.listOf mkStr) "List of font names/families for the main fonts";
    };
  }) "Main font configuration";

  fallbackFonts =
    mkOptDef (t.submodule {
      options = {
        packages = mkOpt (t.listOf mkStr) "List of package names for the fallback fonts";
        names = mkOpt (t.listOf mkStr) "List of font names/families for the fallback fonts";
      };
    }) {
      packages = [];
      names = [];
    } "Fallback font configuration";

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
  directories = mkOptDef (t.attrsOf dirModule) {} "Configuration for managed directories";
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
