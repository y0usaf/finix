#═══════════════════════════ 🌍 SYSTEM OPTIONS 🌍 ═══════════════════════════#
{
  #───────────────────────── BEGIN PROFILES/OPTIONS.NIX ─────────────────────────#
  #
  # This Nix expression defines the core configuration options for the entire system.
  # It acts as a central registry of all configurable aspects, from basic system
  # settings to complex feature toggles and package management.
  #
  # Key Components:
  # - Type System: Defines strict typing for all configuration options
  # - Feature Management: Controls which system capabilities are enabled
  # - Package Sets: Organizes software into logical groups
  # - System Appearance: Manages fonts, DPI, and cursor settings
  #
  # Usage:
  # This file is imported by both configuration.nix and home.nix to ensure
  # consistent options across the entire system configuration.
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
    "defaults"
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

  # Dynamically get module names by reading the modules directory
  moduleFiles = builtins.attrNames (builtins.readDir ./modules);

  # Convert filenames to feature names by removing the .nix extension
  featureNames = builtins.map (name: builtins.elemAt (builtins.split "\\." name) 0) moduleFiles;

  # Create a list of valid features (excluding any special modules you don't want as features)
  # You can add more exclusions to this list as needed
  excludedModules = ["options" "ags" "cursor" "env" "fonts" "git" "gtk" "ssh" "systemd" "xdg"];
  validFeatures = builtins.filter (name: !(builtins.elem name excludedModules)) featureNames;

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
      # Core packages moved to core.nix module
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

  #
  # Export the core features list so that it is available externally.
  #
  inherit _coreFeatures;

  #───────────────────────── END PROFILES/OPTIONS.NIX ───────────────────────────#
}
