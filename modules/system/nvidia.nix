###############################################################################
# NVIDIA Configuration Module
# Comprehensive NVIDIA GPU configuration including:
# - Driver settings and optimizations
# - Power management
# - Application-specific rules
# - Wayland compatibility settings
###############################################################################
{
  config,
  lib,
  pkgs,
  profile,
  ...
}: {
  config = lib.mkIf profile.cfg.core.nvidia.enable {
    ###########################################################################
    # Kernel Parameters
    # Parameters to preserve video memory allocations for better Wayland support
    ###########################################################################
    boot.kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];

    ###########################################################################
    # NVIDIA Driver and Hardware Configuration
    # Core driver settings, power management, and compatibility options
    ###########################################################################
    hardware.nvidia = {
      # Enable DRM kernel mode setting for better Wayland compatibility
      modesetting.enable = true;
      # Enable NVIDIA power management features for better battery life
      powerManagement.enable = true;
      # Use proprietary NVIDIA drivers instead of open-source Nouveau
      open = false;
      # Install nvidia-settings control panel
      nvidiaSettings = true;
      # Use the latest NVIDIA driver from kernel packages
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    ###########################################################################
    # NVIDIA Application Profiles
    # Create the NVIDIA application profiles configuration file
    # This creates a custom profile for preventing video memory reuse
    ###########################################################################
    environment.etc = {
      # Use lib.mkForce to override any conflicting settings
      "nvidia/nvidia-application-profiles-rc".text = lib.mkForce ''
        {
          "rules": [
            {
              "pattern": {
                "feature": "procname",
                "matches": ".Hyprland-wrapped"
              },
              "profile": "No VidMem Reuse"
            },
            {
              "pattern": {
                "feature": "procname",
                "matches": "electron"
              },
              "profile": "No VidMem Reuse"
            },
            {
              "pattern": {
                "feature": "procname",
                "matches": ".firefox-wrapped"
              },
              "profile": "No VidMem Reuse"
            },
            {
              "pattern": {
                "feature": "procname",
                "matches": "firefox"
              },
              "profile": "No VidMem Reuse"
            }
          ]
        }
      '';
    };

    ###########################################################################
    # Video Driver Configuration
    # X server driver settings
    ###########################################################################
    services.xserver.videoDrivers = ["nvidia"];

    ###########################################################################
    # Security & Permissions
    # PolicyKit rules for NVIDIA tools access
    ###########################################################################
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("command_line").indexOf("nvidia-smi") >= 0) {
            return polkit.Result.YES;
        }
      });
    '';

    ###########################################################################
    # Environment Variables
    # NVIDIA-specific environment settings for Wayland compatibility
    ###########################################################################
    environment.variables = {
      # Enable NVIDIA on Wayland
      GBM_BACKEND = "nvidia-drm";
      LIBVA_DRIVER_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      # Additional NVIDIA capabilities
      NVIDIA_DRIVER_CAPABILITIES = "all";
      # Waydroid-specific NVIDIA settings
      WAYDROID_EXTRA_ARGS = "--gpu-mode host";
      GALLIUM_DRIVER = "nvidia";
      LIBGL_DRIVER_NAME = "nvidia";
    };
  };
}
