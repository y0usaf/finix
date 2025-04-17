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
  host,
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

      ###########################################################################
      # Udev Rules
      # Device management and permissions
      ###########################################################################
      udev.extraRules = ''
        # Vial rules for non-root access:
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users"
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", TAG+="uaccess"
      '';
    };
  };
}

