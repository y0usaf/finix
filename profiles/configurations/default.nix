###############################################################################
# NixOS System Configuration
# Complete system configuration including core settings, hardware, services,
# and user environment
# - Core system identity and behavior
# - Hardware and boot configuration
# - Service management and security
# - User accounts and environment
###############################################################################
{
  # The following variables are injected by the NixOS module system:
  #   - config: The cumulative system configuration.
  #   - lib: Library functions for list manipulation, options handling, etc.
  #   - pkgs: The collection of available Nix packages.
  #   - profile: A user-defined profile specifying many system preferences.
  #   - inputs: External inputs (like additional packages or modules).
  #   - ...: Any extra parameters.
  config,
  lib,
  pkgs,
  profile,
  inputs,
  ...
}: let
  ###########################################################################
  # Feature Toggles
  # Extract feature toggles from 'profile.features'
  ###########################################################################
  enableNvidia = profile.modules.core.nvidia.enable;
  enableAmdGpu = profile.modules.core.amdgpu.enable;
  enableWayland = profile.modules.ui.wayland.enable;
  enableHyprland = profile.modules.ui.hyprland.enable;
  enableGaming = profile.modules.apps.gaming.enable;
  enableAndroid = profile.modules.apps.android.enable;
in {
  ###########################################################################
  # Module Imports
  # Additional configuration modules for enhanced modularity
  ###########################################################################
  imports = [
    ../../modules/core/env.nix # Contains environment-specific options and definitions.
  ];

  config = {
    ###########################################################################
    # Core System Settings
    # System identity and behavior configuration
    ###########################################################################
    system.stateVersion = profile.stateVersion; # Ensures compatibility when upgrading.
    time.timeZone = profile.timezone; # Set the system's time zone.
    networking.hostName = profile.hostname; # Define the system's hostname.
    nixpkgs.config.allowUnfree = true; # Allow installation of unfree (proprietary) packages.

    ###########################################################################
    # Nix-LD Configuration
    # Support for running dynamically linked executables
    ###########################################################################
    programs.nix-ld.enable = true;

    ###########################################################################
    # Nix Package Management
    # Package manager configuration for performance and caching
    ###########################################################################
    nix = {
      package = pkgs.nixVersions.stable;
      settings = {
        auto-optimise-store = true;
        max-jobs = "auto";
        cores = 0;
        experimental-features = ["nix-command" "flakes"];
        sandbox = true;
        trusted-users = ["root" profile.username];
        builders-use-substitutes = true;
        fallback = true;

        substituters = [
          "https://cache.nixos.org"
          "https://hyprland.cachix.org"
          "https://chaotic-nyx.cachix.org"
          "https://nyx.cachix.org"
          "https://cuda-maintainers.cachix.org"
          "https://nix-community.cachix.org"
          "https://nix-gaming.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
          "nyx.cachix.org-1:xH6G0MO9PrpeGe7mHBtj1WbNzmnXr7jId2mCiq6hipE="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        ];
      };
      extraOptions = "";
    };

    ###########################################################################
    # Boot & Hardware Configuration
    # Boot loader, EFI, kernel modules, and system parameters
    ###########################################################################
    boot = {
      loader = {
        systemd-boot = {
          enable = true; # Use systemd-boot as the boot loader.
          configurationLimit = 20; # Retain up to 20 boot configurations.
        };
        efi = {
          canTouchEfiVariables = true; # Allow modifying EFI variables.
          efiSysMountPoint = "/boot"; # Mount point for the EFI partition.
        };
      };
      # Use a custom kernel package variant.
      kernelPackages = pkgs.linuxPackages_cachyos;
      # Load extra kernel modules for specific hardware functions.
      kernelModules =
        [
          "kvm-amd"
          "k10temp"
          "nct6775"
          "ashmem_linux"
          "binder_linux"
        ]
        ++ lib.optionals enableAmdGpu ["amdgpu"];
      kernel.sysctl = {
        "kernel.unprivileged_userns_clone" = 1; # Allow unprivileged processes to create user namespaces.
      };
      # AMD GPU kernel parameters (conditional)
      kernelParams = lib.mkIf enableAmdGpu [
        "amdgpu.ppfeaturemask=0xffffffff"
        "amdgpu.dpm=1"
      ];
    };

    ###########################################################################
    # Hardware-Specific Settings
    # Configuration for specific hardware drivers and graphics
    ###########################################################################
    hardware = {
      # Nvidia configuration (conditional)
      nvidia = lib.mkIf enableNvidia {
        # Enable DRM kernel mode setting for better Wayland compatibility
        modesetting.enable = true;
        # Enable NVIDIA power management features for better battery life
        powerManagement.enable = true;
        # Use proprietary NVIDIA drivers instead of open-source Nouveau
        open = false;
        # Install nvidia-settings control panel
        nvidiaSettings = true;
        # Build the Nvidia driver (with version and checksum checks) using mkDriver from the kernel packages.
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "570.86.16"; # Specific version to ensure compatibility.
          sha256_64bit = "sha256-RWPqS7ZUJH9JEAWlfHLGdqrNlavhaR1xMyzs8lJhy9U="; # Checksum for 64-bit binaries.
          openSha256 = "sha256-DuVNA63+pJ8IB7Tw2gM4HbwlOh1bcDg2AN2mbEU9VPE="; # Checksum for open variant (unused here).
          settingsSha256 = "sha256-9rtqh64TyhDF5fFAYiWl3oDHzKJqyOW3abpcf2iNRT8="; # Checksum for the settings tool.
          usePersistenced = false; # Do not use persistenced; manage persistence manually.
        };
      };

      graphics = {
        enable = true;
        enable32Bit = true;
      };
      i2c.enable = true;
    };

    ###########################################################################
    # Services Setup
    # System services including display, audio, and device management
    ###########################################################################
    services = {
      # Conditionally include the Nvidia video driver in the X server configuration.
      xserver.videoDrivers = lib.mkMerge [
        (lib.mkIf enableNvidia ["nvidia"])
        (lib.mkIf enableAmdGpu ["amdgpu"])
      ];

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

    ###########################################################################
    # Security & Permissions
    # System security measures and access control
    ###########################################################################
    security = {
      rtkit.enable = true; # Enable real-time priority management (often needed for audio/video tasks).
      polkit.enable = true; # Enable PolicyKit for fine-grained permission control.
      # Extra Polkit rules to automatically allow execution of "nvidia-smi" without prompts.
      polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.policykit.exec" &&
              action.lookup("command_line").indexOf("nvidia-smi") >= 0) {
              return polkit.Result.YES;
          }
        });
      '';
      # Configure sudo so that the primary user can run all commands without a password.
      sudo.extraRules = [
        {
          users = [profile.username]; # The user defined in the profile.
          commands = [
            {
              command = "ALL"; # Allow all commands.
              options = ["NOPASSWD"]; # No password prompt for these commands.
            }
          ];
        }
      ];
    };

    ###########################################################################
    # User Environment & Programs
    # User-facing applications and environment configuration
    ###########################################################################
    programs = {
      # Conditional configuration for the Hyprland window manager:
      # Only enable if both Wayland and Hyprland are desired features.
      hyprland = lib.mkIf (enableWayland && enableHyprland) {
        enable = true;
        xwayland.enable = true; # Enable XWayland to support legacy X11 apps.
        # Use the Hyprland package corresponding to the current system.
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      };
    };

    ###########################################################################
    # User Account Settings
    # User accounts, permissions, and shell configuration
    ###########################################################################
    users.users.${profile.username} = {
      isNormalUser = true; # Defines the account as a standard user account.
      shell = pkgs.zsh; # Set Zsh as the default shell for this user.
      extraGroups =
        [
          "wheel" # Group that typically grants sudo permissions.
          "networkmanager" # Allows management of network connections.
          "video" # Grants permissions for video hardware usage.
          "audio" # Provides access to audio subsystems.
          "input" # Necessary for access to keyboard and mouse devices.
        ]
        ++ lib.optionals enableGaming [
          "gamemode" # Optionally include the 'gamemode' group for performance tweaks during gaming.
        ];
      ignoreShellProgramCheck = true; # Skip validating that the shell is in /etc/shells.
    };

    ###########################################################################
    # Networking & Virtualisation
    # Network management and container/VM solutions
    ###########################################################################
    networking.networkmanager.enable = true; # Turn on NetworkManager to manage network connections.
    virtualisation = {
      lxd.enable = true; # Enable LXD container hypervisor.
      waydroid = lib.mkIf enableAndroid {
        enable = true; # Enable Waydroid to run Android apps on NixOS.
      };
    };

    ###########################################################################
    # XDG Desktop Portal
    # Desktop integration services for applications
    ###########################################################################
    xdg.portal = lib.mkIf enableWayland {
      enable = true;
      xdgOpenUsePortal = true; # Route xdg-open calls through the portal for better integration.
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk # Add GTK-based portal support.
      ];
    };

    ###########################################################################
    # Environment Variables
    # System-wide environment configuration
    ###########################################################################
    environment.variables = {
      NIXOS_PROFILE = "y0usaf-desktop";
    };
  };
}
