###############################################################################
# Network and Virtualization Configuration Module
# Network management and container/VM solutions:
# - NetworkManager configuration
# - Virtualization tools (LXD, Waydroid, Docker, Podman)
# - XDG desktop portal integration
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  hostHome,
  ...
}: {
  config = {
    ###########################################################################
    # Networking & Virtualisation
    # Network management and container/VM solutions
    ###########################################################################
    networking.networkmanager.enable = true; # Turn on NetworkManager to manage network connections.
    virtualisation = {
      lxd.enable = true; # Enable LXD container hypervisor.
      waydroid = lib.mkIf hostHome.cfg.programs.android.enable {
        enable = true; # Enable Waydroid to run Android apps on NixOS.
      };
      docker = lib.mkIf hostHome.cfg.dev.docker.enable {
        enable = true; # Enable Docker daemon
        enableOnBoot = true; # Start Docker on boot
      };
      podman = lib.mkIf hostHome.cfg.dev.docker.enable {
        enable = true;
      };
    };

    ###########################################################################
    # XDG Desktop Portal
    # Desktop integration services for applications
    ###########################################################################
    xdg.portal = lib.mkIf hostHome.cfg.ui.wayland.enable {
      enable = true;
      xdgOpenUsePortal = true; # Route xdg-open calls through the portal for better integration.
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk # Add GTK-based portal support.
      ];
    };
  };
}
