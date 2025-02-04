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
}: {
  #── 🏠 Core Home Settings ──────────────────#
  home = {
    username = profile.username;
    homeDirectory = profile.homeDirectory;
    stateVersion = profile.stateVersion;
    enableNixpkgsReleaseCheck = false;
  };

  #── 📦 Package Management ─────────────────#
  home.packages = with pkgs; let
    options = import ./options.nix {inherit lib;};

    # Core and feature-based packages
    featurePackages = lib.flatten (
      [options.packageSets.default.core]
      ++ (map (
          feature:
            if builtins.hasAttr feature options.packageSets.default
            then options.packageSets.default.${feature}
            else []
        )
        profile.features)
    );

    # User profile-specific packages
    userPkgs = map (app: pkgs.${app.package}) [
      profile.defaultTerminal
      profile.defaultBrowser
      profile.defaultFileManager
      profile.defaultLauncher
      profile.defaultIde
      profile.defaultMediaPlayer
      profile.defaultImageViewer
      profile.defaultDiscord
    ];
  in
    (map (name: pkgs.${name}) featurePackages) ++ userPkgs;

  #── 🔧 Program Configurations ────────────#
  imports = with lib; let
    # Helper function to conditionally import feature configs
    importFeature = feature: optionals (builtins.elem feature profile.features);
  in
    [
      # Core configurations
      ./zsh.nix
      ./ssh.nix
      ./git.nix
      ./xdg.nix
      ./fonts.nix
      ./foot.nix
      ./gtk.nix
      ./cursor.nix
    ]
    # Feature-based configurations
    ++ importFeature "hyprland" [./hyprland.nix]
    ++ importFeature "ags" [./ags.nix]
    ++ importFeature "gaming" [./gaming.nix]
    ++ importFeature "neovim" [./nvim.nix]
    ++ importFeature "android" [./android.nix]
    ++ importFeature "webapps" [./webapps.nix]
    ++ importFeature "wallust" [./wallust.nix];

  #── 📦 Core Programs ──────────────────────#
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

  #── 🔧 System Configurations ──────────────#
  dconf.enable = true;

  #── 🔄 Systemd Services ─────────────────#
  systemd.user = {
    startServices = "sd-switch";

    services = {
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

      format-nix = {
        Unit.Description = "Format Nix files on change";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.alejandra}/bin/alejandra .";
          WorkingDirectory = "/home/y0usaf/nixos";
        };
      };
    };

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
