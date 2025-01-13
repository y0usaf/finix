#===============================================================================
#
#                     Home Manager Configuration
#
# Description:
#     Primary configuration file for Home Manager, managing user-specific packages
#     and configurations. This includes:
#     - User package installations
#     - Program configurations (OBS, Git, etc.)
#     - Systemd user services for file formatting and git operations
#
# Author: y0usaf
# Last Modified: 2025
#
#===============================================================================
{
  config,
  pkgs,
  lib,
  inputs,
  globals,
  ...
}: {
  #-----------------------------------------------------------------------------
  # Home Manager Core Settings
  #-----------------------------------------------------------------------------
  home = {
    username = globals.username;
    homeDirectory = globals.homeDirectory;

    #---------------------------------------------------------------------------
    # Backup Configuration
    #---------------------------------------------------------------------------
    activation = {
      backupConfig = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
        if [ -d "$HOME/.config" ]; then
          $DRY_RUN_CMD mv $HOME/.config $HOME/.config.backup-$(date +%Y%m%d_%H%M%S)
        fi
      '';
    };
  };

  #-----------------------------------------------------------------------------
  # User Packages
  #-----------------------------------------------------------------------------
  home.packages = with pkgs; [
    #---------------------------------------------------------------------------
    # Development Tools
    #---------------------------------------------------------------------------
    neovim
    cmake
    meson
    bottom
    code-cursor
    alejandra

    #---------------------------------------------------------------------------
    # Web Applications
    #---------------------------------------------------------------------------
    firefox
    vesktop

    #---------------------------------------------------------------------------
    # Terminal and System Utilities
    #---------------------------------------------------------------------------
    foot
    pavucontrol
    nitch
    microfetch
    sway-launcher-desktop
    pcmanfm
    syncthing
    lsd

    #---------------------------------------------------------------------------
    # Gaming
    #---------------------------------------------------------------------------
    steam
    protonup-qt
    gamemode
    prismlauncher

    #---------------------------------------------------------------------------
    # Media and Streaming
    #---------------------------------------------------------------------------
    imv
    mpv
    vlc
    stremio
    ffmpeg
    cmus

    #---------------------------------------------------------------------------
    # Wayland Utilities
    #---------------------------------------------------------------------------
    grim
    slurp
    wl-clipboard

    #---------------------------------------------------------------------------
    # External Inputs
    #---------------------------------------------------------------------------
    inputs.uv2nix.packages.${pkgs.system}.uv-bin
  ];

  #-----------------------------------------------------------------------------
  # Program Configurations
  #-----------------------------------------------------------------------------
  imports = [
    ./hyprland.nix
    ./zsh.nix
    ./ssh.nix
    ./git.nix
    ./xdg.nix
  ];

  #-----------------------------------------------------------------------------
  # OBS Studio Configuration
  #-----------------------------------------------------------------------------
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval
      obs-vkcapture
      inputs.obs-image-reaction.packages.${pkgs.system}.default
    ];
  };

  #-----------------------------------------------------------------------------
  # Package Manager Configuration
  #-----------------------------------------------------------------------------
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/y0usaf/nixos";
  };

  #-----------------------------------------------------------------------------
  # System State and Version
  #-----------------------------------------------------------------------------
  home.stateVersion = globals.stateVersion;

  #-----------------------------------------------------------------------------
  # Systemd User Services
  #-----------------------------------------------------------------------------

  #---------------------------------------------------------------------------
  # Nix Format Service
  #---------------------------------------------------------------------------
  systemd.user.services.format-nix = {
    Unit = {
      Description = "Format Nix files on change";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.alejandra}/bin/alejandra .";
      WorkingDirectory = "/home/y0usaf/nixos";
    };
  };

  systemd.user.paths.format-nix = {
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

  #---------------------------------------------------------------------------
  # Git Auto-Push Service
  #---------------------------------------------------------------------------
  systemd.user.services.git-auto-push = {
    Unit = {
      Description = "Push NixOS config changes after successful build";
      After = "format-nix.service";
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "git-auto-push" ''
        cd /home/y0usaf/nixos
        if git diff-index --quiet HEAD --; then
          exit 0
        fi
        git add .
        git commit -m "feat: system update $(date '+%Y-%m-%d %H:%M')"
        git push
      '';
      WorkingDirectory = "/home/y0usaf/nixos";
    };
  };

  systemd.user.paths.git-auto-push = {
    Unit = {
      Description = "Watch NixOS config directory for successful builds";
    };
    Path = {
      PathChanged = "/home/y0usaf/nixos/result";
      Unit = "git-auto-push.service";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
