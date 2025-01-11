#===============================================================================
#
#                     Home Manager Configuration
#
#===============================================================================

{ config, pkgs, inputs, ... }:

{
  home.username = "y0usaf";
  home.homeDirectory = "/home/y0usaf";
  
  programs.home-manager.enable = true;

  home.sessionVariables = {
    ZDOTDIR = "$HOME/.config/zsh";
  };
  
  #-----------------------------------------------------------------------------
  # User Packages
  #-----------------------------------------------------------------------------
  home.packages = with pkgs; [
    #-------------------------------------------------------------------------
    # Development Tools
    #-------------------------------------------------------------------------
    neovim
    cmake
    meson
    bottom
    
    #-------------------------------------------------------------------------
    # Web Applications
    #-------------------------------------------------------------------------
    firefox
    vesktop
    
    #-------------------------------------------------------------------------
    # Terminal and System Utilities
    #-------------------------------------------------------------------------
    foot
    pavucontrol
    nitch
    sway-launcher-desktop
    pcmanfm
    
    #-------------------------------------------------------------------------
    # Gaming
    #-------------------------------------------------------------------------
    steam
    protonup-qt
    gamemode
    prismlauncher
    
    #-------------------------------------------------------------------------
    # Media and Streaming
    #-------------------------------------------------------------------------
    imv
    mpv
    vlc
    stremio
    
    #-------------------------------------------------------------------------
    # Wayland Utilities
    #-------------------------------------------------------------------------
    grim
    slurp
    wl-clipboard
    
    #-------------------------------------------------------------------------
    # Streaming and Recording (OBS)
    #-------------------------------------------------------------------------
    obs-studio
    obs-studio-plugins.wlrobs  # Wayland screen capture
    obs-studio-plugins.obs-backgroundremoval
    obs-studio-plugins.obs-vkcapture
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/y0usaf/nixos";
  };

  programs.zsh = {
    enable = true;
  };
  
  home.stateVersion = "24.11";
}
