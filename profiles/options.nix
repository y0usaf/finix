#─────────────────────────── 🌍 SYSTEM OPTIONS 🌍 ───────────────────────────#
{
  lib,
  pkgs,
  ...
}: let
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
  # Allow defaultAppModule to be defined either as a dictionary with keys package and command,
  # or using the shorthand tuple syntax { pkg, "cmd" }.
  defaultAppModule = t.union [
    (t.submodule {
      options = {
        package = mkOptDef t.pkg null "Package derivation to install";
        command = mkOptDef mkStr null "Command to execute the application; defaults to package name if null";
      };
    })
    (t.tuple [ t.pkg mkStr ])
  ];

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
      pkgs.git
      pkgs.curl
      pkgs.wget
      pkgs.cachix
      pkgs.unzip
      pkgs.bash
      pkgs.vim
      pkgs.dconf
      pkgs.lsd
      pkgs.alejandra
      pkgs.lm_sensors
      pkgs.bottom
      pkgs.tree
    ];
    wayland = [
      pkgs.grim
      pkgs.slurp
      pkgs."wl-clipboard"
      pkgs.hyprpicker
    ];
    media = [
      pkgs.pavucontrol
      pkgs.ffmpeg
      pkgs."yt-dlp-light"
      pkgs.vlc
      pkgs.stremio
      pkgs.cmus
    ];
    python = [
      pkgs.python3
    ];
    hyprland = [
      pkgs.hyprwayland-scanner
    ];
    syncthing = [
      pkgs.syncthing
    ];
    creative = [
      pkgs.pinta
      pkgs.gimp
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
  corePackages = mkOptDef (t.listOf t.pkg) packageSets.core "Essential packages that will always be installed";
  packageSets = mkOptDef (t.attrsOf (t.listOf t.pkg)) packageSets "Package sets organized by feature";
  features = mkOptDef (t.listOf (t.enum validFeatures)) [] "List of enabled features";
  personalPackages = mkOptDef (t.listOf t.pkg) [] "List of additional packages chosen by the user";

  ########################################
  #         System Appearance            #
  ########################################
  fonts = mkOpt (t.submodule {
    options = {
      main = mkOpt (t.listOf (t.tuple [t.package mkStr])) "List of [package, fontName] tuples for main fonts";
      fallback = mkOptDef (t.listOf (t.tuple [t.package mkStr])) [] "List of [package, fontName] tuples for fallback fonts";
    };
  }) "System font configuration";

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
  bookmarks = mkOptDef (t.listOf mkStr) [] "GTK bookmarks";

  ########################################
  #          Git Configurations          #
  ########################################
  gitName = mkOpt mkStr "Git username.";
  gitEmail = mkOpt mkStr "Git email address.";
  gitHomeManagerRepo = mkOpt mkStr "URL of the Home Manager repository.";
}
