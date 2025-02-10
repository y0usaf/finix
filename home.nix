#─────────────────────── 🏠 HOME MANAGER CONFIG ────────────────────────#
# This configuration file is used by Home Manager to define and assemble   #
# user-specific settings on your Nix system. Each change in this file will    #
# require a rebuild with Home Manager to take effect. The structure is split  #
# into several blocks: imports, variable definitions, and final configurations.#
#─────────────────────────────────────────────────────────────────────────────#
{
  # Parameters provided to this configuration:
  # - config: Global configuration context from Home Manager.
  # - pkgs: The package collection available for building derivations.
  # - lib: Nix library containing utility functions and helper methods.
  # - inputs: External inputs, often provided via a flake.
  # - profile: The user's profile containing personal settings.
  # - ...: Any additional arguments.
  config,
  pkgs,
  lib,
  inputs,
  profile,
  ...
}: let
  ####################################################################
  # Import external options:
  #   We bring in additional options from a separate file (./profiles/options.nix).
  #   This external file defines package sets and other overridable options.
  #   By using import with { inherit lib pkgs; }, we pass along the necessary
  #   dependencies needed by options.nix.
  ####################################################################
  options = import ./profiles/options.nix {inherit lib pkgs;};

  ####################################################################
  # Define common variables for readability:
  #   These variables simplify later references within the config.
  ####################################################################
  packageSet = options.packageSets.default; # The default package set supplied via options.nix.
  features = profile.features; # List of enabled features specified in the user profile.

  ####################################################################
  # Compute feature-based packages:
  #   Starting with a base 'core' package, we add additional packages for each
  #   enabled feature. For each feature, if a corresponding attribute exists
  #   in packageSet, its package is added to the list. Otherwise, nothing is added.
  ####################################################################
  packageForFeature = feature:
    if builtins.hasAttr feature packageSet # Check if packageSet contains the current feature.
    then packageSet.${feature} # Return the package for the feature if available.
    else []; # Otherwise, return an empty list.

  # Build a flat list of packages:
  #   - Start with the core package set.
  #   - Append packages based on each feature enabled in the user profile.
  ####################################################################
  featurePackages = lib.flatten ([packageSet.core] ++ (map packageForFeature features));

  ####################################################################
  # Compute user profile-specific packages:
  #   The profile is expected to have several default applications defined
  #   (like terminal, browser, file manager, etc.). Each app should be a derivation
  #   (or contain one) and we extract the package from each attribute.
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
  # For each application, extract its package attribute.
  ####################################################################
  userPackages = map (app: app.package) defaultApps;

  ####################################################################
  # Combine final package list:
  #   Merge:
  #     1. Feature packages (computation above including core and feature-specific ones).
  #     2. User-specific packages (extracted from default apps in the profile).
  #     3. Any additional personal packages specified in the profile.
  #   This final aggregate list will be handled by Home Manager.
  ####################################################################
  finalPackages = featurePackages ++ userPackages ++ profile.personalPackages;

  ####################################################################
  # Helper function: Conditional Module Importer
  #   Although not used directly here, this helper facilitates the conditional
  #   import of modules based on whether a feature is enabled in the user profile.
  ####################################################################
  importFeature = feature: lib.optionals (builtins.elem feature features);
in {
  #─────────────────────── 🏠 Core Home Settings ──────────────────────────#
  home = {
    username = profile.username; # Specify the user's username.
    homeDirectory = profile.homeDirectory; # Define the path to the user's home directory.
    stateVersion = profile.stateVersion; # Indicate the state version for Home Manager's internal tracking.
    enableNixpkgsReleaseCheck = false; # Disable release checking to avoid unexpected updates.
    packages = finalPackages; # Provide the aggregated package list to be installed.
  };

  #──────────────────────────────────────────────────────────────#
  #                Home-manager Module Imports
  #──────────────────────────────────────────────────────────────#
  # Dynamically import additional Home Manager modules based on enabled features.
  # The modules are assumed to reside within the "./modules" directory and are
  # conditionally included if they exist.
  imports = lib.flatten (map (
    feature: let
      modulePath = "${./modules}/${feature}.nix"; # Construct the expected path for the module.
    in
      lib.optional (builtins.pathExists modulePath) modulePath
  ) (options._coreFeatures ++ features));

  #──────────────────────────────────────────────────────────────#
  #                     Program Configurations
  #──────────────────────────────────────────────────────────────#
  # Configure the 'nh' program (presumably a Home Manager utility) with
  # user-specific settings.
  programs.nh = {
    enable = true; # Enable the program.
    flake = profile.flakeDir; # Specify the directory for flake configuration.
    clean = {
      # Configure cleanup behavior:
      enable = true; # Enable periodic cleaning.
      dates = "weekly"; # Set cleanup frequency to weekly.
      extraArgs = "--keep-since 7d"; # Additional argument: keep items newer than 7 days.
    };
  };

  #──────────────────────────────────────────────────────────────#
  #                    Service Configurations
  #──────────────────────────────────────────────────────────────#
  # Configure the status of the Syncthing service.
  # It is enabled only if the user profile includes "syncthing" in its features.
  services.syncthing = {
    enable = lib.elem "syncthing" features;
  };

  #──────────────────────────────────────────────────────────────#
  #                    System Configurations
  #──────────────────────────────────────────────────────────────#
  # Activate the dconf system. This is commonly used in GNOME and other desktop
  # environments for managing configuration settings in a centralized manner.
  dconf.enable = true;
}
