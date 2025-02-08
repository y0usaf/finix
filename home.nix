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
  #
  # Core modules are always imported.
  # Additional modules are conditionally imported based on features.
  #──────────────────────────────────────────────────────────────#
  imports = with lib;
    [
      # Core module imports
      ./modules/zsh.nix
      ./modules/ssh.nix
      ./modules/git.nix
      ./modules/xdg.nix
      ./modules/fonts.nix
      ./modules/foot.nix
      ./modules/gtk.nix
      ./modules/cursor.nix
      ./modules/systemd.nix
      ./modules/firefox.nix
    ]
    ++ importFeature "hyprland" [./modules/hyprland.nix]
    ++ importFeature "ags" [./modules/ags.nix]
    ++ importFeature "gaming" [./modules/gaming.nix]
    ++ importFeature "neovim" [./modules/nvim.nix]
    ++ importFeature "android" [./modules/android.nix]
    ++ importFeature "webapps" [./modules/webapps.nix]
    ++ importFeature "wallust" [./modules/wallust.nix];

  #──────────────────────────────────────────────────────────────#
  #                     Program Configurations
  #
  # Configuration for various programs like zsh, nh, and obs-studio.
  #──────────────────────────────────────────────────────────────#
  programs = {
    zsh.enable = true;

    zellij = {
      enable = true;
      enableZshIntegration = true;
    };

    nh = {
      enable = true;
      flake = profile.flakeDir;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep-since 7d";
      };
    };

    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-backgroundremoval
        obs-vkcapture
        inputs.obs-image-reaction.packages.${pkgs.system}.default
      ];
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
