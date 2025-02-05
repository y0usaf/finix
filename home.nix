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
  options = import ./options.nix {inherit lib;};

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
  # reference the corresponding package in pkgs.
  ####################################################################
  userPackages = map (app: pkgs.${app.package}) [
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
  #   - Map each feature package name to pkgs.<name>
  #   - Concatenate with the user-specific packages computed above.
  ####################################################################
  finalPackages = (map (name: pkgs.${name}) featurePackages) ++ userPackages;

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
  #                    System Configurations
  #
  # In this case, only dconf is enabled.
  #──────────────────────────────────────────────────────────────#
  dconf.enable = true;

  #──────────────────────────────────────────────────────────────#
  #                    Systemd User Services
  #
  # This section defines the user services and file system watches.
  #──────────────────────────────────────────────────────────────#
  systemd.user = {
    startServices = "sd-switch";

    services = {
      ################################################################
      # Polkit GNOME Authentication Agent Service
      ################################################################
      polkit-gnome-authentication-agent-1 = {
        Unit = {
          Description = "polkit-gnome-authentication-agent-1";
          WantedBy = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };

      ################################################################
      # Format Nix Files Service
      #
      # A oneshot service to run alejandra (a Nix formatter) on changes.
      ################################################################
      format-nix = {
        Unit.Description = "Format Nix files on change";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.alejandra}/bin/alejandra .";
          WorkingDirectory = "/home/y0usaf/nixos";
        };
      };
    };

    ################################################################
    # File Watch Path for auto-triggering Nix formatting
    ################################################################
    paths.format-nix = {
      Unit.Description = "Watch NixOS config directory for changes";
      Path = {
        PathModified = "/home/y0usaf/nixos";
        Unit = "format-nix.service";
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
