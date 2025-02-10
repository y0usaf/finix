#─────────────────────── 🏠 HOME MANAGER CONFIG ────────────────────────#
# 🏠 User-specific settings | Home-manager rebuild needed for changes  #
#──────────────────────────────────────────────────────────────────────#
{
  config,
  pkgs,
  lib,
  inputs,
  profile,
  ...
}: let
  ####################################################################
  # Import external options
  ####################################################################
  options = import ./profiles/options.nix {inherit lib pkgs;};

  ####################################################################
  # Define common variables for readability
  ####################################################################
  packageSet = options.packageSets.default;
  features = profile.features;

  ####################################################################
  # Compute feature-based packages.
  #
  # We start with the core package set and then append packages for each
  # feature (if defined in the package set, otherwise nothing is added).
  ####################################################################
  packageForFeature = feature:
    if builtins.hasAttr feature packageSet
    then packageSet.${feature}
    else [];

  featurePackages = lib.flatten ([packageSet.core] ++ (map packageForFeature features));

  ####################################################################
  # Compute user profile-specific packages.
  #
  # Each app attribute (e.g. defaultTerminal, defaultBrowser, etc.) should
  # be a derivation. We simply extract the package for each.
  ####################################################################
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
  userPackages = map (app: app.package) defaultApps;

  ####################################################################
  # Combine final package list:
  #   - Feature packages (already derivations)
  #   - User-specific packages
  #   - Any additional personal packages from the profile
  ####################################################################
  finalPackages = featurePackages ++ userPackages ++ profile.personalPackages;

  ####################################################################
  # Helper function: Conditionally import modules based on profile features.
  # Returns the module only if the feature is enabled.
  ####################################################################
  importFeature = feature: lib.optionals (builtins.elem feature features);
in {
  #─────────────────────── 🏠 Core Home Settings ──────────────────#
  home = {
    username = profile.username;
    homeDirectory = profile.homeDirectory;
    stateVersion = profile.stateVersion;
    enableNixpkgsReleaseCheck = false;
    packages = finalPackages;
  };

  #──────────────────────────────────────────────────────────────#
  #                Home-manager Module Imports
  #──────────────────────────────────────────────────────────────#
  imports = lib.flatten (map (
    feature: let
      modulePath = "${./modules}/${feature}.nix";
    in
      lib.optional (builtins.pathExists modulePath) modulePath
  ) (options._coreFeatures ++ features));

  #──────────────────────────────────────────────────────────────#
  #                     Program Configurations
  #──────────────────────────────────────────────────────────────#
  programs.nh = {
    enable = true;
    flake = profile.flakeDir;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 7d";
    };
  };

  #──────────────────────────────────────────────────────────────#
  #                    Service Configurations
  #──────────────────────────────────────────────────────────────#
  services.syncthing = {
    enable = lib.elem "syncthing" features;
  };

  #──────────────────────────────────────────────────────────────#
  #                    System Configurations
  #──────────────────────────────────────────────────────────────#
  dconf.enable = true;
}
