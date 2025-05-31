###############################################################################
# Hyprland Window Manager Configuration
# Hyprland window manager setup:
# - Hyprland package and configuration
# - XWayland support
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  hostHome,
  inputs,
  ...
}: {
  config = {
    ###########################################################################
    # Hyprland Window Manager
    # Tiling window manager for Wayland
    ###########################################################################
    programs.hyprland = lib.mkIf (hostHome.cfg.ui.wayland.enable && hostHome.cfg.ui.hyprland.enable) {
      enable = true;
      xwayland.enable = true; # Enable XWayland to support legacy X11 apps.
      # Use the Hyprland package corresponding to the current system.
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
  };
}
