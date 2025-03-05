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
  # Import External Options
  ###########################################################################
  options = import ./profiles/options.nix {inherit lib pkgs;};

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
  imports = lib.flatten (map (
      feature: let
        modulePath = "${./modules}/${feature}.nix";
      in
        lib.optional (builtins.pathExists modulePath) modulePath
    )
    features);

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
