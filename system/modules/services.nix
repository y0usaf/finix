###############################################################################
# Services Configuration Module
# System services configuration:
# - Audio via Pipewire
# - SCX scheduling service
# - D-Bus communication
# - Udev device management
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
    # Services Setup
    # System services including display, audio, and device management
    ###########################################################################
    services = {
      ###########################################################################
      # Audio via Pipewire
      # Modern audio server with compatibility layers
      ###########################################################################
      pipewire = {
        enable = true;
        alsa = {
          enable = true; # Enable ALSA compatibility layer.
          support32Bit = true; # Support for 32-bit audio applications.
        };
        pulse.enable = true; # Enable PulseAudio emulation for compatibility.
      };

      ###########################################################################
      # SCX Custom Service
      # System scheduling and tuning service
      ###########################################################################
      scx = {
        enable = true; # Activate the SCX service.
        scheduler = "scx_lavd"; # Specify the scheduler mode.
        package = pkgs.scx.rustscheds; # Use the rust-based scheduler package.
      };

      ###########################################################################
      # D-Bus Configuration
      # Inter-process communication system
      ###########################################################################
      dbus = {
        enable = true;
        packages = [
          pkgs.dconf # A backend for system configuration.
          pkgs.gcr # GNOME crypto resource management library.
        ];
      };

      # UDEV rules for Vial have been moved to the system/modules/hardware/input.nix file
    };
  };
}
