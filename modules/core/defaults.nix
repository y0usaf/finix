#═══════════════════════════ 🔧 SYSTEM DEFAULTS 🔧 ═══════════════════════════#
{
  #───────────────────────── BEGIN PROFILES/DEFAULTS.NIX ─────────────────────────#
  #
  # This Nix expression defines default applications and directory configurations
  # for the system. It centralizes all default application choices and important
  # filesystem locations.
  #
  # Key Components:
  # - Default Applications: Configures preferred programs for common tasks
  # - Directory Structure: Manages important filesystem locations
  #
  # Usage:
  # This file is imported by configuration.nix and home.nix to ensure
  # consistent defaults across the entire system configuration.
  #
  #───────────────────────────────────────────────────────────────────────────────#
  lib,
  ...
}: let
  ######################################################################
  #                        Type Definitions & Helpers                    #
  ######################################################################
  t = lib.types;

  # Define a shorthand for string type
  mkStr = t.str;
  # Define shorthand for boolean type
  mkBool = t.bool;

  # mkOpt builds an option with a type and a description.
  mkOpt = type: description: lib.mkOption {inherit type description;};

  # mkOptDef builds an option with a type, default value, and a description.
  mkOptDef = type: default: description: lib.mkOption {inherit type default description;};

  ######################################################################
  #                           Submodule Options                          #
  ######################################################################

  # The defaultAppModule is used to configure default applications like browsers,
  # editors, etc.
  defaultAppModule = t.submodule {
    options = {
      # package: Specifies the Nix package derivation to install for the application.
      # Can be null if you only want to specify a command without installing a package.
      package = mkOptDef (t.nullOr t.pkg) null "Package derivation to install (optional)";
      # command: Specifies the command to run the application.
      # If null, the default behavior is to use the package name.
      command = mkOptDef mkStr null "Command to execute the application. Defaults to package name if null";
    };
  };

  # The dirModule submodule is used for configuring directories. It includes
  # settings for specifying the absolute path and whether the directory should be
  # automatically created if missing.
  dirModule = t.submodule {
    options = {
      # path: Defines the absolute path to the directory.
      path = mkOpt mkStr "Absolute path to the directory";
      # create: Determines if the directory should be created automatically if not found.
      create = mkOptDef mkBool true "Whether to create the directory if it doesn't exist";
    };
  };
in {
  options = {
    ######################################################################
    #                       Default Applications Options                   #
    ######################################################################

    # Moved defaults inside modules to match the profile's structure
    modules = mkOpt (t.submodule {
      options = {
        defaults = mkOpt (t.submodule {
          options = {
            browser = mkOpt defaultAppModule "Default web browser configuration.";
            editor = mkOpt defaultAppModule "Default text editor configuration.";
            ide = mkOpt defaultAppModule "Default IDE configuration.";
            terminal = mkOpt defaultAppModule "Default terminal emulator configuration.";
            fileManager = mkOpt defaultAppModule "Default file manager configuration.";
            launcher = mkOpt defaultAppModule "Default application launcher configuration.";
            discord = mkOpt defaultAppModule "Default Discord client configuration.";
            archiveManager = mkOpt defaultAppModule "Default archive manager configuration.";
            imageViewer = mkOpt defaultAppModule "Default image viewer configuration.";
            mediaPlayer = mkOpt defaultAppModule "Default media player configuration.";
          };
        }) "Default application configurations";
      };
    }) "Module configurations";

    ######################################################################
    #                       Directory Configurations                       #
    ######################################################################

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
  };

  #───────────────────────── END PROFILES/DEFAULTS.NIX ───────────────────────────#
}
