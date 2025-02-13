#─────────────────────────── 🌍 SYSTEM OPTIONS 🌍 ───────────────────────────#
{
  #───────────────────────── BEGIN PROFILES/OPTIONS.NIX ─────────────────────────#
  #
  # This Nix expression defines a comprehensive set of system options using
  # a modular approach. It sets up type definitions, helpers, submodule options,
  # feature lists, package sets, validations, and many system configurations.
  # Every section is documented in detail to explain its purpose and structure.
  #
  #───────────────────────────────────────────────────────────────────────────────#
  lib,
  pkgs,
  ...
}: let
  ######################################################################
  #                        Type Definitions & Helpers                    #
  ######################################################################
  #
  # The "t" alias gives us access to lib.types which helps in constructing
  # option types and submodules, making the configuration more robust.
  #
  t = lib.types;

  # Define a shorthand for string type
  mkStr = t.str;
  # Define shorthand for boolean type
  mkBool = t.bool;
  # Define shorthand for a list of strings type
  mkListOfStr = t.listOf t.str;

  # mkOpt builds an option with a type and a description.
  # It wraps lib.mkOption and passes the type and description attributes.
  mkOpt = type: description: lib.mkOption {inherit type description;};

  # mkOptDef builds an option with a type, default value, and a description.
  # Useful when a default value is required.
  mkOptDef = type: default: description: lib.mkOption {inherit type default description;};

  ######################################################################
  #                           Submodule Options                          #
  ######################################################################
  #
  # Submodules allow us to nest sets of options. These two submodules will be used
  # for default application configurations and directory configurations.
  #
  # The defaultAppModule is used to configure default applications like browsers,
  # editors, etc.
  #
  defaultAppModule = t.submodule {
    options = {
      # package: Specifies the Nix package derivation to install for the application.
      package = mkOptDef t.pkg null "Package derivation to install";
      # command: Specifies the command to run the application.
      # If null, the default behavior is to use the package name.
      command = mkOptDef mkStr null "Command to execute the application. Defaults to package name if null";
    };
  };

  #
  # The dirModule submodule is used for configuring directories. It includes
  # settings for specifying the absolute path and whether the directory should be
  # automatically created if missing.
  #
  dirModule = t.submodule {
    options = {
      # path: Defines the absolute path to the directory.
      path = mkOpt mkStr "Absolute path to the directory";
      # create: Determines if the directory should be created automatically if not found.
      create = mkOptDef mkBool true "Whether to create the directory if it doesn't exist";
    };
  };

  ######################################################################
  #                            Feature Lists                             #
  ######################################################################
  #
  # Features represent different aspect modules or capabilities in the system.
  # There are two lists:
  #   1. _coreFeatures - features always enabled.
  #   2. validFeatures - additional optional features which a user can enable.
  #

  # Core system features that are always enabled. They include utilities, shells,
  # theming, and basic browser support.
  _coreFeatures = [
    "core" # Basic system utilities and common tools.
    "zsh" # Z shell configuration.
    "ssh" # SSH client/server configuration.
    "git" # Git configuration and version control.
    "xdg" # XDG base directories compliance.
    "fonts" # System font configuration.
    "foot" # Foot terminal emulator configuration.
    "gtk" # GTK theming and GUI configuration.
    "cursor" # Cursor theming settings.
    "systemd" # Systemd service and daemon management.
    "firefox" # Firefox browser support.
  ];

  # List of valid, user-selectable features for further configuration.
  validFeatures = [
    # Development tools and editors.
    "python"
    "nvim"
    "vscode"

    # Desktop Environment tools and compositors.
    "hyprland"
    "ags"
    "wayland"
    "wallust"

    # Hardware specific or support features.
    "nvidia"
    "android"

    # Additional use cases like gaming, media playback, creative work, etc.
    "gaming"
    "media"
    "music"
    "creative"
    "virtualization"
    "backup"
    "webapps"
    "syncthing"
    "streamlink"

    # Multiplexer tool for terminal session management.
    "zellij"

    # Feature for ChatGPT integration.
    "chatgpt"

    # New feature
    "sync-tokens"
  ];

  ######################################################################
  #                         Package Sets Definitions                     #
  ######################################################################
  #
  # Each feature (both core and optional) corresponds to a set of Nix packages.
  # Core packages are defined in corePackageSets and are always installed.
  # Optional packages appear in optionalPackageSets and are installed based on the
  # features enabled by the user.
  #

  # Core package sets correspond to essential features.
  corePackageSets = {
    core = [
      pkgs.git # Git: essential for version control.
      pkgs.curl # Curl: for data transfers via various protocols.
      pkgs.wget # Wget: tool for retrieving files over HTTP/HTTPS/FTP.
      pkgs.cachix # Cachix: binary caching solution.
      pkgs.unzip # Unzip: utility to extract compressed files.
      pkgs.bash # Bash: a widely-used shell.
      pkgs.vim # Vim: a classic text editor.
      pkgs.lsd # Lsd: improved ls command with icons and colorization.
      pkgs.alejandra # Alejandra: code formatter for shell scripts.
      pkgs.tree # Tree: displays directory structures in a tree-like format.
      pkgs.dconf # Dconf: configuration system for GNOME.
      pkgs.lm_sensors # LM Sensors: hardware monitoring and sensor readings.
      pkgs.bottom # Bottom: graphical system monitor.
    ];
    zsh = [
      pkgs.zsh # Zsh: a modern shell environment.
    ];
    ssh = [
      pkgs.openssh # OpenSSH: secure shell protocol suite.
    ];
    git = [
      pkgs.git # Git: reiterated to ensure its availability.
    ];
    foot = [
      pkgs.foot # Foot: terminal emulator.
    ];
    gtk = [
      pkgs.gtk3 # GTK3: graphical toolkit.
      pkgs.gsettings-desktop-schemas # Desktop schemas for GTK settings.
    ];
    firefox = [
      pkgs.firefox # Firefox: web browser.
    ];
  };

  #
  # Optional package sets allow users to enable additional features.
  #
  optionalPackageSets = {
    wayland = [
      pkgs.grim # Grim: screenshot utility for Wayland.
      pkgs.slurp # Slurp: screen region selector tool.
      pkgs.wl-clipboard # WL-clipboard: clipboard utility on Wayland.
      pkgs.hyprpicker # Hyprpicker: specific utility likely for Hyprland.
    ];
    media = [
      pkgs.pavucontrol # Pavucontrol: sound mixer for PulseAudio.
      pkgs.ffmpeg # FFmpeg: multimedia framework.
      pkgs.yt-dlp-light # yt-dlp-light: lightweight tool for downloading videos.
      pkgs.vlc # VLC: versatile media player.
      pkgs.stremio # Stremio: media streaming application.
      pkgs.cmus # cmus: terminal-based music player.
    ];
    python = [
      pkgs.python3 # Python3: interpreter for Python scripts.
    ];
    hyprland = [
      pkgs.hyprwayland-scanner # Hyprwayland-scanner: tool associated with Hyprland.
    ];
    syncthing = [
      pkgs.syncthing # Syncthing: files synchronization tool.
    ];
    creative = [
      pkgs.pinta # Pinta: simple painting application.
      pkgs.gimp # GIMP: feature-rich image editor.
    ];
    music = [
      pkgs.cmus # cmus: command-line music player
      pkgs.cava # Cava: console-based audio visualizer
    ];
  };

  #
  # Merge the two sets (core and optional) so that later the package sets
  # option is initialized with a complete mapping.
  #
  packageSets = corePackageSets // optionalPackageSets;

  ######################################################################
  #                         Validation Functions                         #
  ######################################################################
  #
  # To maintain consistency between packages and features, we perform validations:
  #
  # 1. packageSetsWithoutFeatures: Ensure every package set has a corresponding feature.
  # 2. featuresWithoutPackageSets: Check that every feature has a corresponding package set.
  #

  # Scan for package sets that do not correspond to any valid or core feature.
  packageSetsWithoutFeatures = builtins.filter (
    setName:
      !(builtins.elem setName validFeatures)
      && !(builtins.elem setName _coreFeatures)
  ) (builtins.attrNames packageSets);

  # Scan for features that do not have a corresponding package set.
  featuresWithoutPackageSets = builtins.filter (
    feature:
      !(builtins.hasAttr feature corePackageSets)
      && !(builtins.hasAttr feature optionalPackageSets)
  ) (validFeatures ++ _coreFeatures);

  # Assert and throw an error if any package set is found without a matching feature.
  _validatePackageSets =
    lib.assertMsg (packageSetsWithoutFeatures == [])
    "Found package sets without corresponding features: ${builtins.toString packageSetsWithoutFeatures}";
in {
  ######################################################################
  #                        Core System Options                           #
  ######################################################################
  #
  # The following options define basic system settings such as the username,
  # hostname, home directory, and more.
  #

  # The primary username for the system.
  username = mkOpt mkStr "The username for the system.";

  # The hostname of the system.
  hostname = mkOpt mkStr "The system hostname.";

  # The home directory path of the user.
  homeDirectory = mkOpt mkStr "The path to the user's home directory.";

  # A version string used to track the system's state and configuration migrations.
  stateVersion = mkOpt mkStr "The system state version.";

  # The system timezone (e.g., 'Europe/Berlin').
  timezone = mkOpt mkStr "The system timezone.";

  ######################################################################
  #                      Package Management Options                      #
  ######################################################################
  #
  # Options below control which packages (and package sets) are installed.
  #

  # Core packages that are always installed; drawn from the core package sets.
  corePackages = mkOptDef (t.listOf t.pkg) packageSets.core "Essential packages that will always be installed";

  # The complete mapping of package sets for different features.
  packageSets = mkOptDef (t.attrsOf (t.listOf t.pkg)) packageSets "Package sets organized by feature";

  # List of additional features enabled by the user. Core features are automatically included.
  features =
    mkOptDef
    (t.listOf (t.enum validFeatures))
    []
    "List of enabled features (core features are automatically included)";

  # The list of core features that are mandated to be enabled.
  coreFeatures =
    mkOptDef
    (t.listOf t.str)
    _coreFeatures
    "List of core features that are always enabled";

  # Additional user-specified packages.
  personalPackages = mkOptDef (t.listOf t.pkg) [] "List of additional packages chosen by the user";

  ######################################################################
  #                       System Appearance Options                      #
  ######################################################################
  #
  # Visual and appearance settings, including fonts, DPI, and cursor sizes.
  #

  # Font configuration using a submodule; supports both main and fallback fonts.
  fonts = mkOpt (t.submodule {
    options = {
      # 'main': Primary fonts specified as a list of tuples [package, fontName].
      main = mkOpt (t.listOf (t.tuple [t.package mkStr])) "List of [package, fontName] tuples for main fonts";
      # 'fallback': Fallback fonts if the main fonts are unavailable, defaults to an empty list.
      fallback = mkOptDef (t.listOf (t.tuple [t.package mkStr])) [] "List of [package, fontName] tuples for fallback fonts";
    };
  }) "System font configuration";

  # Base font size used as the reference for scaling other UI elements.
  baseFontSize = mkOptDef t.int 12 "Base font size that other UI elements should scale from";

  # The size of the mouse/system cursor.
  cursorSize = mkOptDef t.int 24 "Size of the system cursor";

  # The system's Display DPI setting to determine scaling and clarity.
  dpi = mkOptDef t.int 96 "Display DPI setting for the system";

  ######################################################################
  #                       Default Applications Options                     #
  ######################################################################
  #
  # Definitions for default application configurations are provided via the
  # defaultAppModule submodule. These include browser, editor, IDE, terminal, etc.
  #

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

  ######################################################################
  #                       Directory Configurations                       #
  ######################################################################
  #
  # Options for important directories; these can be automatically managed.
  #

  # Managed directories defined as an attribute set using the directory submodule.
  directories = mkOptDef (t.attrsOf dirModule) {} "Configuration for managed directories";

  # Directory where the flake repository resides.
  flakeDir = mkOpt mkStr "The directory where the flake lives.";

  # Directory for storing music files.
  musicDir = mkOpt mkStr "Directory for music files.";

  # Directory for digital camera images (DCIM).
  dcimDir = mkOpt mkStr "Directory for pictures (DCIM).";

  # Directory associated with Steam (gaming platform).
  steamDir = mkOpt mkStr "Directory for Steam.";

  # Directory dedicated to wallpapers.
  wallpaperDir = mkOpt mkStr "Wallpaper directory.";

  # Directory dedicated to wallpaper videos.
  wallpaperVideoDir = mkOpt mkStr "Wallpaper video directory.";

  # GTK bookmarks, typically used in file managers for quick access.
  bookmarks = mkOptDef (t.listOf mkStr) [] "GTK bookmarks";

  ######################################################################
  #                          Git Configurations                          #
  ######################################################################
  #
  # Configuration options related to Git. These include the user's Git name,
  # email and the URL for the Home Manager repository.
  #

  gitName = mkOpt mkStr "Git username.";
  gitEmail = mkOpt mkStr "Git email address.";
  gitHomeManagerRepo = mkOpt mkStr "URL of the Home Manager repository.";

  #
  # Export the core features list so that it is available externally.
  #
  inherit _coreFeatures;

  #───────────────────────── END PROFILES/OPTIONS.NIX ───────────────────────────#
}
