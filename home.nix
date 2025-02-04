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
  #── 🏠 Core Settings ──────────────────────#
  home = {
    username = profile.username;
    homeDirectory = profile.homeDirectory;
    stateVersion = profile.stateVersion;
    enableNixpkgsReleaseCheck = false;
  };

  #── 🔧 Program Configurations ────────────#
  imports =
    [
      ./zsh.nix
      ./ssh.nix
      ./git.nix
      ./xdg.nix
      ./fonts.nix
      ./foot.nix
      ./gtk.nix
      ./cursor.nix
    ]
    ++ lib.optionals (builtins.elem "hyprland" profile.features) [
      ./hyprland.nix
    ]
    ++ lib.optionals (builtins.elem "ags" profile.features) [
      ./ags.nix
    ]
    ++ lib.optionals (builtins.elem "gaming" profile.features) [
      ./gaming.nix
    ]
    ++ lib.optionals (builtins.elem "neovim" profile.features) [
      ./nvim.nix
    ]
    ++ lib.optionals (builtins.elem "android" profile.features) [
      ./android.nix
    ]
    ++ lib.optionals (builtins.elem "webapps" profile.features) [
      ./webapps.nix
    ]
    ++ lib.optionals (builtins.elem "wallust" profile.features) [
      ./wallust.nix
    ];

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

  #── 📦 User Packages ───────────────────────#
  home.packages = with pkgs; let
    options = import ./options.nix {inherit lib;};

    # Get all packages based on enabled features
    featurePackages = lib.flatten (
      # Core packages are always included
      [options.packageSets.default.core]
      ++
      # Add packages for each enabled feature
      (map (
          feature:
            if builtins.hasAttr feature options.packageSets.default
            then options.packageSets.default.${feature}
            else []
        )
        profile.features)
    );

    #── 👤 User Profile Packages ─────────────#
    userPkgs = [
      (pkgs.${profile.defaultTerminal.package})
      (pkgs.${profile.defaultBrowser.package})
      (pkgs.${profile.defaultFileManager.package})
      (pkgs.${profile.defaultLauncher.package})
      (pkgs.${profile.defaultIde.package})
      (pkgs.${profile.defaultMediaPlayer.package})
      (pkgs.${profile.defaultImageViewer.package})
      (pkgs.${profile.defaultDiscord.package})
    ];
  in
    (map (name: pkgs.${name}) featurePackages) ++ userPkgs;

  #── 🔧 System Configurations ──────────────#
  dconf.enable = true;

  #── 🔄 Systemd Services ─────────────────#
  systemd.user = {
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
        Unit = {
          Description = "Format Nix files on change";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.alejandra}/bin/alejandra .";
          WorkingDirectory = "/home/y0usaf/nixos";
        };
      };
    };

    paths = {
      format-nix = {
        Unit = {
          Description = "Watch NixOS config directory for changes";
        };
        Path = {
          PathModified = "/home/y0usaf/nixos";
          Unit = "format-nix.service";
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };
    };

    startServices = "sd-switch";
  };
}
