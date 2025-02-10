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
  # The core package set is added first.
  # For every feature in the profile, if it exists in the package set,
  # its package set is used; otherwise an empty list is returned.
  ####################################################################
  featurePackages = lib.flatten (
    [packageSet.core]
    ++ (map (
        feature:
          if builtins.hasAttr feature packageSet
          then packageSet.${feature}
          else []
      )
      features)
  );

  ####################################################################
  # Compute user profile-specific packages.
  #
  # Each app attribute (e.g. defaultTerminal, defaultBrowser, etc.)
  # is expected to be a derivation. We simply map over these and extract
  # the package.
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
  #   - Features packages (already derivations)
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
