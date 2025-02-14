#===============================================================================
#                          💻 NixOS Laptop Configuration 💻
#===============================================================================
# This file details the entire NixOS system configuration for a laptop setup,
# including power management, AMD-specific optimizations, and laptop hardware support.
#
# ⚠️  Root access required | System rebuild needed for changes
#===============================================================================
{
  config,
  lib,
  pkgs,
  profile,
  inputs,
  ...
}: let
  #############################################################
  # Extract feature toggles from 'profile.features'
  #############################################################
  enableWayland = builtins.elem "wayland" profile.features;
  enableHyprland = builtins.elem "hyprland" profile.features;
  enableGaming = builtins.elem "gaming" profile.features;
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules/env.nix
  ];

  config = {
    #############################################################
    # Core System Settings
    #############################################################
    system.stateVersion = profile.stateVersion;
    time.timeZone = profile.timezone;
    networking.hostName = profile.hostname;
    nixpkgs.config.allowUnfree = true;

    #############################################################
    # AMD-specific Hardware Configuration
    #############################################################
    hardware = {
      cpu.amd.updateMicrocode = true;
      enableRedistributableFirmware = true;

      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          rocm-opencl-icd
          rocm-opencl-runtime
          amdvlk
        ];
      };

      bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
    };

    #############################################################
    # Power Management & Thermal Control
    #############################################################
    services = {
      power-profiles-daemon.enable = true;
      thermald.enable = true;

      tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        };
      };

      #############################################################
      # Display Server & Input Configuration
      #############################################################
      xserver = {
        enable = true;
        displayManager.gdm = {
          enable = true;
          wayland = true;
        };

        videoDrivers = ["amdgpu"];

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

      #############################################################
      # System Updates & Firmware
      #############################################################
      fwupd.enable = true;
    };

    #############################################################
    # Boot Configuration & Kernel Modules
    #############################################################
    boot.kernelModules = [
      "kvm-amd" # AMD virtualization
      "k10temp" # AMD CPU temperature monitoring
      "amdgpu" # AMD GPU support
      "acpi_call" # ThinkPad-specific ACPI calls
    ];

    powerManagement = {
      enable = true;
      cpuFreqGovernor = "schedutil";
    };

    #############################################################
    # System Packages
    #############################################################
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
