###############################################################################
# Programs Configuration Module
# User-facing applications and environment configuration:
# - Hyprland window manager (conditional)
# - Additional application configurations
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
    # User Environment & Programs
    # User-facing applications and environment configuration
    ###########################################################################
    programs = {
      # Conditional configuration for the Hyprland window manager:
      # Only enable if both Wayland and Hyprland are desired features.
      hyprland = lib.mkIf (hostHome.cfg.ui.wayland.enable && hostHome.cfg.ui.hyprland.enable) {
        enable = true;
        xwayland.enable = true; # Enable XWayland to support legacy X11 apps.
        # Use the Hyprland package corresponding to the current system.
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      };
    };
  };
}
