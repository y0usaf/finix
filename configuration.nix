#===============================================================================
#
#                     NixOS System Configuration
#
#===============================================================================

{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
  
  #-----------------------------------------------------------------------------
  # System Configuration
  #-----------------------------------------------------------------------------
  time.timeZone = "America/Toronto";
  networking.hostName = "y0usaf-desktop";
  system.stateVersion = "24.11";
  
  #-----------------------------------------------------------------------------
  # Nix Package Manager Settings
  #-----------------------------------------------------------------------------
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nixpkgs-unstable.cachix.org"
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
  };
  
  #-----------------------------------------------------------------------------
  # Hardware Configuration
  #-----------------------------------------------------------------------------
  hardware = {
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
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
  services.xserver.videoDrivers = [ "nvidia" ];
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };
  
  #-----------------------------------------------------------------------------
  # Global Environment Variables
  #-----------------------------------------------------------------------------
  environment = {
    sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONEVWL = "1";
    };
    # Essential system packages
    systemPackages = with pkgs; [
      git
      curl
      wget
      vim
      cpio
    ];
  };
  
  #-----------------------------------------------------------------------------
  # System Fonts
  #-----------------------------------------------------------------------------
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
  ];
  
  #-----------------------------------------------------------------------------
  # User Configuration
  #-----------------------------------------------------------------------------
  users.users."y0usaf" = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
  };
  
  #-----------------------------------------------------------------------------
  # Sudo Configuration
  #-----------------------------------------------------------------------------
  security.sudo.extraRules = [{
    users = [ "y0usaf" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
  
  #-----------------------------------------------------------------------------
  # System Services
  #-----------------------------------------------------------------------------
  networking.networkmanager.enable = true;
  programs.zsh.enable = true;
}
