{
  config,
  lib,
  pkgs,
  profile,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/env.nix
  ];

  config = {
    # Core System Settings
    system.stateVersion = profile.stateVersion;
    time.timeZone = profile.timezone;
    networking.hostName = profile.hostname;
    nixpkgs.config.allowUnfree = true;

    # AMD-specific optimizations
    hardware.cpu.amd.updateMicrocode = true;
    hardware.enableRedistributableFirmware = true;

    # Graphics Configuration
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        rocm-opencl-icd
        rocm-opencl-runtime
        amdvlk
      ];
    };

    # Power Management
    services.power-profiles-daemon.enable = true;
    services.thermald.enable = true;
    powerManagement = {
      enable = true;
      cpuFreqGovernor = "schedutil";
    };

    # Fan Control and System Management
    boot.kernelModules = [
      "kvm-amd"     # AMD virtualization
      "k10temp"     # AMD CPU temperature monitoring
      "amdgpu"      # AMD GPU support
      "acpi_call"   # ThinkPad-specific ACPI calls
    ];

    # Enable laptop-specific services
    services = {
      # Display
      xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        displayManager.gdm.wayland = true;
        
        # AMD GPU configuration
        videoDrivers = ["amdgpu"];
        
        # Touchpad support
        libinput = {
          enable = true;
          touchpad = {
            tapping = true;
            naturalScrolling = true;
            middleEmulation = true;
            disableWhileTyping = true;
          };
        };
      };

      # Battery and power management
      tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        };
      };

      # Enable firmware updates
      fwupd.enable = true;
    };

    # Hardware-specific settings
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    # Additional system packages
    environment.systemPackages = with pkgs; [
      # AMD-specific tools
      radeontop
      corectrl
      ryzenadj
      
      # System monitoring
      lm_sensors
      powertop
      
      # Laptop utilities
      acpi
      brightnessctl
    ];
  };
} 