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
  host,
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
      hyprland = lib.mkIf (host.cfg.ui.wayland.enable && host.cfg.ui.hyprland.enable) {
        enable = true;
        xwayland.enable = true; # Enable XWayland to support legacy X11 apps.
        # Use the Hyprland package corresponding to the current system.
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      };
    };

    # Add custom version of Bambu Studio to system packages
    environment.systemPackages = [
      # Override Bambu Studio with specific version
      (pkgs.bambu-studio.overrideAttrs (oldAttrs: {
        version = "01.00.01.50";
        src = pkgs.fetchFromGitHub {
          owner = "bambulab";
          repo = "BambuStudio";
          rev = "v01.00.01.50";
          hash = "sha256-7mkrPl2CQSfc1lRjl1ilwxdYcK5iRU//QGKmdCicK30=";
        };
      }))
    ];
  };
}
