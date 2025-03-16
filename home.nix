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
  # FEATURES LOGIC - Isolated for future removal
  ###########################################################################
  t = lib.types;

  # Module discovery logic
  findModules = dir: let
    contents = builtins.readDir dir;
    handleEntry = name: type:
      if type == "regular" && lib.hasSuffix ".nix" name
      then ["${dir}/${name}"]
      else if type == "directory"
      then findModules "${dir}/${name}"
      else [];
  in
    lib.flatten (lib.mapAttrsToList handleEntry contents);

  moduleFiles = findModules ./modules;

  # Extract feature names from paths
  validFeatures =
    builtins.map (
      path: let
        fileName = builtins.baseNameOf path;
        nameWithoutExt = builtins.elemAt (builtins.split "\\." fileName) 0;
      in
        nameWithoutExt
    )
    moduleFiles;

  # Feature-based package computation
  features = profile.features;

  # This function doesn't seem to be working as intended
  # It's checking if a feature name exists as a key in options
  # But feature names are not keys in the options attrset
  featurePackages = []; # Simplified as the original logic appears broken

  # Module imports logic
  imports = let
    # Core modules
    coreModules =
      builtins.filter (
        path: lib.hasPrefix "${toString ./modules/core}/" path
      )
      moduleFiles;

    # Feature-based modules
    featureModules = lib.flatten (map (
        feature: let
          isDirectory = builtins.pathExists (./modules + "/${feature}");
          directoryModules =
            if isDirectory
            then
              builtins.filter (
                path: lib.hasPrefix "${toString ./modules}/${feature}/" path
              )
              moduleFiles
            else [];

          exactMatchModules =
            builtins.filter (
              path: let
                fileName = builtins.baseNameOf path;
                nameWithoutExt = builtins.elemAt (builtins.split "\\." fileName) 0;
              in
                nameWithoutExt == feature
            )
            moduleFiles;
        in
          directoryModules ++ exactMatchModules
      )
      features);
  in
    coreModules ++ featureModules;
  ###########################################################################
  # END FEATURES LOGIC
  ###########################################################################

  ###########################################################################
  # Package Management
  ###########################################################################
  # Extract default applications from profile
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

  # Combine all package sources
  finalPackages = featurePackages ++ userPackages ++ profile.personalPackages;
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

  # Import modules based on features
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
