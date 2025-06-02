###############################################################################
# Hyprland Window Manager Module
# Configures the Hyprland Wayland compositor with:
# - Core settings and plugins (hy3)
# - Customizable keybindings and window rules
# - NVIDIA compatibility options
# - XDG portal integration
###############################################################################
{
  config,
  pkgs,
  lib,
  inputs,

  hostSystem,
  hostHome,
  ...
}: let
  cfg = config.cfg.ui.hyprland;
in {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./core.nix
    ./keybindings.nix
    ./window-rules.nix
    ./monitors.nix
    ./ags-integration.nix
  ];

  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.ui.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";
    flake = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to use Hyprland from flake inputs instead of nixpkgs";
      };
    };
    hy3 = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable the hy3 tiling layout plugin";
      };
    };
    group = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable the group layout mode";
      };
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = [
      pkgs.hyprwayland-scanner # Tool associated with Hyprland
    ];

    ###########################################################################
    # XDG Portal Configuration
    ###########################################################################
    xdg.portal = {
      xdgOpenUsePortal = true;
      configPackages = [
        (
          if cfg.flake.enable
          then inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
          else pkgs.xdg-desktop-portal-hyprland
        )
      ];
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = "*";
    };

    ###########################################################################
    # Environment Variables
    ###########################################################################
    home.sessionVariables = {
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };

    ###########################################################################
    # Hyprland Configuration
    ###########################################################################
    wayland.windowManager.hyprland = {
      # Core Activation and System Settings
      enable = true;
      xwayland.enable = true;
      systemd = {
        enable = true;
        variables = ["--all"];
      };

      # Package Definitions
      package =
        if cfg.flake.enable
        then inputs.hyprland.packages.${pkgs.system}.hyprland
        else pkgs.hyprland;
      portalPackage =
        if cfg.flake.enable
        then inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
        else pkgs.xdg-desktop-portal-hyprland;
      plugins = lib.mkIf cfg.hy3.enable [
        # Always use hy3 from flake inputs since it's not available in nixpkgs
        inputs.hy3.packages.${pkgs.system}.hy3
      ];
    };

    ###########################################################################
    # Shell Environment Configuration
    ###########################################################################
    programs.zsh = {
      envExtra = lib.mkIf hostSystem.cfg.hardware.nvidia.enable ''
        # Hyprland NVIDIA environment variables
        export LIBVA_DRIVER_NAME=nvidia
        export XDG_SESSION_TYPE=wayland
        export GBM_BACKEND=nvidia-drm
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export WLR_NO_HARDWARE_CURSORS=1
        export XCURSOR_SIZE=${toString hostHome.cfg.appearance.cursorSize}
        export NIXOS_OZONE_WL=1
      '';
    };
  };
}
