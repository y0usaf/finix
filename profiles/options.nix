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
    "appearance" # System appearance settings.
  ];

  # Dynamically get module names by reading the modules directory
  moduleFiles = builtins.attrNames (builtins.readDir ./modules);

  # Convert filenames to feature names by removing the .nix extension
  featureNames = builtins.map (name: builtins.elemAt (builtins.split "\\." name) 0) moduleFiles;

  # Create a list of valid features (excluding core features)
  validFeatures = builtins.filter (name: !(builtins.elem name _coreFeatures)) featureNames;
in {
  ######################################################################
  #                      Package Management Options                      #
  ######################################################################
  #
  # Options below control which packages (and package sets) are installed.
  #

  # Core packages that are always installed
  corePackages = mkOptDef (t.listOf t.pkg) [] "Essential packages that will always be installed";

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

  #
  # Export the core features list so that it is available externally.
  #
  inherit _coreFeatures;

  #───────────────────────── END PROFILES/OPTIONS.NIX ───────────────────────────#
}
