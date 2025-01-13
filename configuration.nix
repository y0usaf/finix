#===============================================================================
#
#                     NixOS System Configuration
#
# Description:
#     Primary system configuration file for NixOS. Manages:
#     - System-wide settings
#     - Hardware configuration
#     - Service enablement
#     - User management
#     - Security settings
#
# Author: y0usaf
# Last Modified: 2025
#
#===============================================================================
{
  config,
  lib,
  pkgs,
  globals,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./env.nix
    ./cachix.nix
  ];

  #-----------------------------------------------------------------------------
  # System Configuration
  #-----------------------------------------------------------------------------
  time.timeZone = globals.timezone;
  networking.hostName = globals.hostname;
  system.stateVersion = globals.stateVersion;

  #-----------------------------------------------------------------------------
  # Nix Package Manager Settings
  #-----------------------------------------------------------------------------
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
      system-features = ["big-parallel" "kvm" "nixos-test"];
      sandbox = true;
      trusted-users = ["root" "y0usaf"];
      builders-use-substitutes = true;
      fallback = true;

      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  #-----------------------------------------------------------------------------
  # Boot Configuration
  #-----------------------------------------------------------------------------
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  #-----------------------------------------------------------------------------
  # Hardware Configuration
  #-----------------------------------------------------------------------------
  hardware = {
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  #-----------------------------------------------------------------------------
  # Audio Configuration
  #-----------------------------------------------------------------------------
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  #-----------------------------------------------------------------------------
  # Desktop Environment
  #-----------------------------------------------------------------------------
  services.xserver.videoDrivers = ["nvidia"];
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  #-----------------------------------------------------------------------------
  # Global Environment Variables
  #-----------------------------------------------------------------------------
  environment = {
    systemPackages = with pkgs; [
      git
      vim
      curl
      wget
      cachix
      (python3.withPackages (ps:
        with ps; [
          pip
          setuptools
        ]))
    ];
  };

  #-----------------------------------------------------------------------------
  # System Fonts
  #-----------------------------------------------------------------------------
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    nerd-fonts.iosevka-term-slab
  ];

  #-----------------------------------------------------------------------------
  # User Configuration
  #-----------------------------------------------------------------------------
  users.users.${globals.username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel" "networkmanager" "video" "audio" "gamemode"];
    ignoreShellProgramCheck = true;
  };

  #-----------------------------------------------------------------------------
  # Sudo Configuration
  #-----------------------------------------------------------------------------
  security.sudo.extraRules = [
    {
      users = ["y0usaf"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  #-----------------------------------------------------------------------------
  # System Services
  #-----------------------------------------------------------------------------
  networking.networkmanager.enable = true;

  programs.zsh = {
    enable = false;
    enableGlobalCompInit = false;
  };

  # XDG Portal Configuration
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    configPackages = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    xdgOpenUsePortal = true;
  };
}
