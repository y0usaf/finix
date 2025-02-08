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
  # Compute feature-based packages
  #
  # The "core" package set is added first
  # Then for each feature enabled in the user profile, we check that
  # the corresponding attribute exists in options.packageSets.default;
  # if so, we include that set.
  ####################################################################
  featurePackages = lib.flatten (
    [options.packageSets.default.core]
    ++ (map (feature:
      if builtins.hasAttr feature options.packageSets.default
      then options.packageSets.default.${feature}
      else [])
    profile.features)
  );

  ####################################################################
  # Compute user profile-specific packages
  #
  # Each package is derived from the profile settings. For each
  # app attribute (e.g. defaultTerminal, defaultBrowser, etc.), we
  # get the package directly since it's already a derivation.
  ####################################################################
  userPackages = map (app: app.package) [
    profile.defaultTerminal
    profile.defaultBrowser
    profile.defaultFileManager
    profile.defaultLauncher
    profile.defaultIde
    profile.defaultMediaPlayer
    profile.defaultImageViewer
    profile.defaultDiscord
  ];

  ####################################################################
  # Combine final package list:
  #   - Use feature packages directly since they're already derivations
  #   - Concatenate with the user-specific packages
  #   - Add any personal packages specified by the user
  ####################################################################
  finalPackages = featurePackages ++ userPackages ++ profile.personalPackages;

  ####################################################################
  # Helper function: Conditionally import modules based on profile features
  #
  # Returns the provided module only if the feature is enabled.
  ####################################################################
  importFeature = feature: lib.optionals (builtins.elem feature profile.features);
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
  imports = lib.flatten (map (feature: let
    modulePath = ./modules + "/${feature}.nix";
  in
    lib.optional (builtins.pathExists modulePath) modulePath)
  (options._coreFeatures ++ profile.features));

  #──────────────────────────────────────────────────────────────#
  #                     Program Configurations
  #
  # Configuration for various programs like zsh, nh, and obs-studio.
  #──────────────────────────────────────────────────────────────#
  programs = {
    nh = {
      enable = true;
      flake = profile.flakeDir;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep-since 7d";
      };
    };
  };

  #──────────────────────────────────────────────────────────────#
  #                    Service Configurations
  #──────────────────────────────────────────────────────────────#
  services.syncthing = {
    enable = lib.elem "syncthing" profile.features;
  };

  #──────────────────────────────────────────────────────────────#
  #                    System Configurations
  #──────────────────────────────────────────────────────────────#
  dconf.enable = true;
}
