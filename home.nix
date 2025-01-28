#─────────────────────── 🏠 HOME MANAGER CONFIG ────────────────────────#
# 🏠 User-specific settings | Home-manager rebuild needed for changes  #
#──────────────────────────────────────────────────────────────────────#
{
  config,
  pkgs,
  lib,
  inputs,
  globals,
  ...
}: {
  #── 🏠 Core Settings ──────────────────────#
  home = {
    username = globals.username;
    homeDirectory = globals.homeDirectory;
    stateVersion = globals.stateVersion;
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
    ++ lib.optionals globals.enableHyprland [
      ./hyprland.nix
    ]
    ++ lib.optionals globals.enableAgs [
      ./ags.nix
    ];

  #── 📦 Core Programs ──────────────────────#
  programs = {
    zsh.enable = true;

    nh = {
      enable = true;
      flake = globals.flakeDir;
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
  home.packages = with pkgs;
    [
      #── 🎨 Development Tools ─────────────────#
      neovim
      cmake
      meson
      bottom
      code-cursor
      alejandra
      cpio
      pkg-config
      ninja
      gcc
      git
      vim
      curl
      wget
      cachix
      unzip
      lm_sensors
      yt-dlp-light
      bash
      (python3.withPackages (ps:
        with ps; [
          pip
          setuptools
        ]))

      #── 🔧 Terminal and System Utilities ────#
      foot
      pavucontrol
      nitch
      microfetch
      sway-launcher-desktop
      pcmanfm
      syncthing
      lsd
      waybar
      p7zip
      dconf

      #── 🌐 Web Applications ─────────────────#
      firefox
      vesktop
      discord-canary

      #── 🎮 Gaming ────────────────────────────#
      steam
      protonup-qt
      gamemode
      protontricks
      prismlauncher

      #── 📺 Media and Streaming ──────────────#
      imv
      mpv
      vlc
      stremio
      ffmpeg
      cmus

      # Add this to the existing packages section
      chromium
    ]
    ++ lib.optionals globals.enableWayland [
      #── 🖥️ Wayland Utilities ───────────────#
      grim
      slurp
      wl-clipboard
      nwg-wrapper
      hyprpicker
    ];

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

      dbus-hyprland-environment = {
        Unit = {
          Description = "dbus hyprland environment";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";
          RemainAfterExit = true;
        };
        Install = {
          WantedBy = ["graphical-session.target"];
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
