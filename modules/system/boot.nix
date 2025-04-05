###############################################################################
# Boot Configuration Module
# Boot loader and kernel configurations:
# - Boot loader settings
# - EFI configuration
# - Kernel packages and modules
# - System control parameters
###############################################################################
{
  config,
  lib,
  pkgs,
  profile,
  ...
}: {
  config = {
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
        ++ lib.optionals profile.modules.core.amdgpu.enable ["amdgpu"];
      kernel.sysctl = {
        "kernel.unprivileged_userns_clone" = 1; # Allow unprivileged processes to create user namespaces.
      };
      # AMD GPU kernel parameters (conditional)
      kernelParams = lib.mkIf profile.modules.core.amdgpu.enable [
        "amdgpu.ppfeaturemask=0xffffffff"
        "amdgpu.dpm=1"
      ];
    };
  };
}
