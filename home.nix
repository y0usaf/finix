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
      ./webapps.nix
    ]
    ++ lib.optionals profile.enableHyprland [
      ./hyprland.nix
    ]
    ++ lib.optionals profile.enableAgs [
      ./ags.nix
    ]
    ++ lib.optionals profile.enableGaming [
      ./gaming.nix
    ]
    ++ lib.optionals profile.enableNeovim [
      ./nvim.nix
    ]
    ++ lib.optionals profile.enableAndroid [
      ./android.nix
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
    #── 🛠️ Essential Packages ─────────────────#
    essentialPkgs = [
      # Core system utilities
      git
      curl
      wget
      cachix
      unzip
      bash
      vim
      dconf
      lsd
      alejandra
      lm_sensors

      # Python with basic packages
      (python3.withPackages (ps:
        with ps; [
          pip
          setuptools
        ]))
    ];

    #── 📦 Optional Packages ─────────────────#
    optionalPkgs = [
      # Development tools
      cmake
      meson
      bottom
      cpio
      pkg-config
      ninja
      gcc

      # Media tools
      pavucontrol
      ffmpeg
      yt-dlp-light
      vlc
      stremio
      cmus
      chromium

      # System utilities
      grim
      slurp
      wl-clipboard
      nwg-wrapper
      hyprpicker
    ];

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
    essentialPkgs ++ optionalPkgs ++ userPkgs;

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
