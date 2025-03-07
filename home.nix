###############################################################################
# Home Manager Configuration
# Central configuration file for user-specific settings
# - Manages user packages and applications
# - Configures user environment and services
# - Handles feature-based module imports
###############################################################################
{
  # Parameters provided to this configuration:
  config,
  pkgs,
  lib,
  inputs,
  profile,
  ...
}: let
  ###########################################################################
  # BEGIN: Options Definitions (formerly in profiles/options.nix)
  ###########################################################################
  t = lib.types;
  mkStr = t.str;
  mkBool = t.bool;
  mkListOfStr = t.listOf t.str;
  mkOpt = type: description: lib.mkOption {inherit type description;};
  mkOptDef = type: default: description: lib.mkOption {inherit type default description;};

  # Dynamically read module filenames and compute valid features.
  # Recursively find all .nix files in the modules directory and its subdirectories
  findModules = dir: let
    contents = builtins.readDir dir;
    handleEntry = name: type:
      if type == "regular" && lib.hasSuffix ".nix" name
      then ["${dir}/${name}"]
      else if type == "directory"
      then findModules "${dir}/${name}"
      else [];
    entries = lib.mapAttrsToList handleEntry contents;
  in
    lib.flatten entries;

  moduleFiles = findModules ./modules;
  # Extract feature names from paths, removing the .nix extension
  validFeatures =
    builtins.map (
      path: let
        fileName = builtins.baseNameOf path;
        nameWithoutExt = builtins.elemAt (builtins.split "\\." fileName) 0;
      in
        nameWithoutExt
    )
    moduleFiles;

  # Option definitions originally provided by profiles/options.nix
  options = {
    corePackages =
      mkOptDef (t.listOf t.pkg) [] "Essential packages that will always be installed";
    features =
      mkOptDef (t.listOf (t.enum validFeatures)) [] "List of enabled features";
    personalPackages =
      mkOptDef (t.listOf t.pkg) [] "List of additional packages chosen by the user";
  };

  ###########################################################################
  # END: Options Definitions (formerly in profiles/options.nix)
  ###########################################################################

  ###########################################################################
  # Define Common Variables
  ###########################################################################
  features = profile.features;

  ###########################################################################
  # Compute Feature-based Packages
  ###########################################################################
  # Helper function that maps a feature name to its package list
  packageForFeature = feature:
    if builtins.hasAttr feature options
    then options.${feature}
    else [];

  # Build a flat list of packages based on enabled features
  featurePackages = lib.flatten (map packageForFeature features);

  ###########################################################################
  # Compute User Profile-specific Packages
  ###########################################################################
  defaultApps = [
    profile.defaultTerminal
    profile.defaultBrowser
    profile.defaultFileManager
    profile.defaultLauncher
    profile.defaultIde
    profile.defaultMediaPlayer
    profile.defaultImageViewer
    profile.defaultDiscord
  ];
  # Extract package attribute from each app and filter out nulls
  userPackages = lib.filter (p: p != null) (map (app: app.package) defaultApps);

  ###########################################################################
  # Combine Final Package List
  ###########################################################################
  finalPackages = featurePackages ++ userPackages ++ profile.personalPackages;

  ###########################################################################
  # Helper Function: Conditional Module Importer
  ###########################################################################
  importFeature = feature: lib.optionals (builtins.elem feature features);

  ###########################################################################
  # Home-manager Module Imports
  ###########################################################################
  imports = let
    # Find all core modules
    coreModules =
      builtins.filter (
        path: lib.hasPrefix "${toString ./modules/core}/" path
      )
      moduleFiles;

    # Feature-based modules
    featureModules = lib.flatten (map (
        feature: let
          # Find all module files that match the feature name
          matchingModules =
            builtins.filter (
              path: let
                fileName = builtins.baseNameOf path;
                nameWithoutExt = builtins.elemAt (builtins.split "\\." fileName) 0;
              in
                nameWithoutExt == feature
            )
            moduleFiles;
        in
          matchingModules
      )
      features);
  in
    coreModules ++ featureModules;
in {
  ###########################################################################
  # Core Home Settings
  ###########################################################################
  home = {
    username = profile.username;
    homeDirectory = profile.homeDirectory;
    stateVersion = profile.stateVersion;
    enableNixpkgsReleaseCheck = false;
    packages = finalPackages;
  };

  ###########################################################################
  # Home-manager Module Imports
  ###########################################################################
  imports = imports;

  ###########################################################################
  # Program Configurations
  ###########################################################################
  programs.nh = {
    enable = true;
    flake = profile.flakeDir;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 7d";
    };
  };

  ###########################################################################
  # Service Configurations
  ###########################################################################
  services.syncthing = {
    enable = lib.elem "syncthing" features;
  };

  ###########################################################################
  # System Configurations
  ###########################################################################
  dconf.enable = true;
}
