#─────────────────────────── 🌍 SYSTEM OPTIONS 🌍 ───────────────────────────#
{lib, ...}: let
  # Type definitions and helpers
  t = lib.types;
  mkStr = t.str;
  mkBool = t.bool;
  mkListOfStr = t.listOf t.str;
  mkOpt = type: description: lib.mkOption {inherit type description;};
  mkOptDef = type: default: description: lib.mkOption {inherit type default description;};

  # Common submodules
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

  # Helper for creating multiple similar options
  mkSubmoduleOptions = attrs: builtins.mapAttrs (name: desc: mkOpt defaultAppModule desc) attrs;

  # Feature definitions
  validFeatures = [
    "hyprland"
    "ags"
    "wayland"
    "nvidia"
    "gaming"
    "development"
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

  # Default packages (internal)
  defaultCorePackages = [
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
  ];
in {
  # Core system identification
  username = mkOpt mkStr "The username for the system.";
  hostname = mkOpt mkStr "The system hostname.";
  homeDirectory = mkOpt mkStr "The path to the user's home directory.";
  stateVersion = mkOpt mkStr "The system state version.";
  timezone = mkOpt mkStr "The system timezone.";

  # Core packages (internal)
  corePackages = mkOptDef mkListOfStr defaultCorePackages "Essential packages that will always be installed";

  # Optional features
  features = mkOptDef (t.listOf (t.enum validFeatures)) [] "List of enabled features";

  # System appearance
  mainFont = mkOpt fontModule "Primary system font configuration";
  fallbackFonts = mkOptDef (t.listOf fontModule) [] "List of fallback fonts in order of preference";
  baseFontSize = mkOptDef t.int 12 "Base font size that other UI elements should scale from";
  cursorSize = mkOptDef t.int 24 "Size of the system cursor";
  dpi = mkOptDef t.int 96 "Display DPI setting for the system";

  # Default applications
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

  # Directory configurations
  flakeDir = mkOpt mkStr "The directory where the flake lives.";
  musicDir = mkOpt mkStr "Directory for music files.";
  dcimDir = mkOpt mkStr "Directory for pictures (DCIM).";
  steamDir = mkOpt mkStr "Directory for Steam.";
  wallpaperDir = mkOpt mkStr "Wallpaper directory.";
  wallpaperVideoDir = mkOpt mkStr "Wallpaper video directory.";

  # Git configurations
  gitName = mkOpt mkStr "Git username.";
  gitEmail = mkOpt mkStr "Git email address.";
  gitHomeManagerRepo = mkOpt mkStr "URL of the Home Manager repository.";
}
