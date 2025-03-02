#===============================================================================
#                          🖥️ NixOS Configuration 🖥️
#===============================================================================
# This file details the entire NixOS system configuration, including
# core system settings, package management, boot/hardware configuration,
# services, security policies, user settings, and more.
#
# Every section has been extensively commented for clarity.
#
# ⚠️  Root access required | System rebuild needed for changes
#===============================================================================
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
  #############################################################
  # Extract feature toggles from 'profile.features'.
  # Each flag becomes true if the corresponding feature string exists.
  #############################################################
  enableNvidia = builtins.elem "nvidia" profile.features;
  enableAmdGpu = builtins.elem "amdgpu" profile.features;
  enableWayland = builtins.elem "wayland" profile.features;
  enableHyprland = builtins.elem "hyprland" profile.features;
  enableGaming = builtins.elem "gaming" profile.features;
in {
  #############################################################
  # Import additional configuration modules.
  # Splitting the configuration enhances modularity and clarity.
  #############################################################
  imports = [
    ../../modules/env.nix # Contains environment-specific options and definitions.
  ];

  config = {
    #############################################################
    # Core System Settings:
    # These settings define system identity and behaviour.
    #############################################################
    system.stateVersion = profile.stateVersion; # Ensures compatibility when upgrading.
    time.timeZone = profile.timezone; # Set the system's time zone.
    networking.hostName = profile.hostname; # Define the system's hostname.
    nixpkgs.config.allowUnfree = true; # Allow installation of unfree (proprietary) packages.

    #############################################################
    # Enable nix-ld for running dynamically linked executables
    #############################################################
    programs.nix-ld.enable = true;

    #############################################################
    # Nix Package Management:
    # Configure the Nix package manager for performance, caching, and build isolation.
    #############################################################
    nix = {
      package = pkgs.nixVersions.stable; # Use the stable Nix package manager.
      settings = {
        auto-optimise-store = true; # Automatically optimize the storage layout.
        max-jobs = "auto"; # Let Nix auto-detect the optimal number of parallel jobs.
        cores = 0; # 0 indicates using all available cores.
        system-features = ["big-parallel" "kvm" "nixos-test"]; # Enable extra system features.
        sandbox = true; # Run builds in a sandbox for isolation.
        trusted-users = ["root" profile.username]; # Allow root and the specified user to perform unconfined builds.
        builders-use-substitutes = true; # Allow builders to fetch substitute builds.
        fallback = true; # Fall back to building if substitutes fail.

        #############################################################
        # Remote Caches (Substituters):
        # These URLs point to various Cachix caches which provide pre-built binaries.
        #############################################################
        substituters = [
          "https://cache.nixos.org"
          "https://hyprland.cachix.org"
          "https://chaotic-nyx.cachix.org"
          "https://nyx.cachix.org"
          "https://cuda-maintainers.cachix.org"
          "https://nix-community.cachix.org"
          "https://nix-gaming.cachix.org"
        ];

        #############################################################
        # Trusted Public Keys:
        # Keys are used to verify the authenticity of binaries fetched from the substituters.
        #############################################################
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
      #############################################################
      # Extra Options:
      # Enabling experimental features such as nix-command and flakes.
      #############################################################
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };

    #############################################################
    # Boot & Hardware Configuration:
    # Settings related to the boot loader, EFI, kernel modules, and sysctl parameters.
    #############################################################
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
          "kvm-amd" # AMD virtualization support.
          "k10temp" # AMD CPU temperature monitoring.
          "nct6775" # Hardware sensor chip for voltage/temperature.
          "ashmem_linux" # Android shared memory.
          "binder_linux" # Android binder driver.
        ]
        ++ lib.optionals enableAmdGpu [
          "amdgpu"
        ];
      kernel.sysctl = {
        "kernel.unprivileged_userns_clone" = 1; # Allow unprivileged processes to create user namespaces.
      };
      # AMD GPU kernel parameters (conditional)
      kernelParams = lib.mkIf enableAmdGpu [
        "amdgpu.ppfeaturemask=0xffffffff" # Enable all power features
        "amdgpu.dpm=1" # Enable power management
      ];
    };

    #############################################################
    # Hardware-Specific Settings:
    # Configuration for specific hardware drivers like Nvidia/AMD and general graphics.
    #############################################################
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

    #############################################################
    # Services Setup:
    # Collection of daemons and services including display servers, audio,
    # custom services, D-Bus, and device management.
    #############################################################
    services = {
      # Conditionally include the Nvidia video driver in the X server configuration.
      xserver.videoDrivers = lib.mkMerge [
        (lib.mkIf enableNvidia ["nvidia"])
        (lib.mkIf enableAmdGpu ["amdgpu"])
      ];

      #############################################################
      # Audio via Pipewire:
      # Configure Pipewire as the primary audio server along with ARM support.
      #############################################################
      pipewire = {
        enable = true;
        alsa = {
          enable = true; # Enable ALSA compatibility layer.
          support32Bit = true; # Support for 32-bit audio applications.
        };
        pulse.enable = true; # Enable PulseAudio emulation for compatibility.
      };

      #############################################################
      # SCX Custom Service:
      # A specific custom service (possibly for scheduling tasks or system tuning).
      #############################################################
      scx = {
        enable = true; # Activate the SCX service.
        scheduler = "scx_lavd"; # Specify the scheduler mode.
        package = pkgs.scx.rustscheds; # Use the rust-based scheduler package.
      };

      #############################################################
      # D-Bus Configuration:
      # Enable D-Bus and include additional packages for configuration management.
      #############################################################
      dbus = {
        enable = true;
        packages = [
          pkgs.dconf # A backend for system configuration.
          pkgs.gcr # GNOME crypto resource management library.
        ];
      };

      #############################################################
      # Extra Udev Rules:
      # Add custom udev rules to modify hardware device permissions.
      # The rules below grant non-root access to specific keyboards matching a serial pattern.
      #############################################################
      udev.extraRules = ''
        # Vial rules for non-root access:
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users"
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", TAG+="uaccess"
      '';
    };

    #############################################################
    # Security & Permissions:
    # Define security measures including Polkit rules and sudo configurations.
    #############################################################
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

    #############################################################
    # User Environment & Programs:
    # Configure the main user account and conditionally enable custom programs.
    #############################################################
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

    #############################################################
    # User Account Settings:
    # Define the primary interactive user's account details, shell, and group memberships.
    #############################################################
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

    #############################################################
    # Networking & Virtualisation:
    # Enable network management and container/virtualisation solutions.
    #############################################################
    networking.networkmanager.enable = true; # Turn on NetworkManager to manage network connections.
    virtualisation = {
      lxd.enable = true; # Enable LXD container hypervisor.
      waydroid = {
        enable = true; # Enable Waydroid to run Android apps on NixOS.
      };
    };

    #############################################################
    # XDG Desktop Portal:
    # Required for proper integration of portal services with desktop environments,
    # especially when using Wayland.
    #############################################################
    xdg.portal = lib.mkIf enableWayland {
      enable = true;
      xdgOpenUsePortal = true; # Route xdg-open calls through the portal for better integration.
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk # Add GTK-based portal support.
      ];
    };

    environment.variables = {
      NIXOS_PROFILE = "y0usaf-desktop";
    };
  };
}
