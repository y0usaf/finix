###############################################################################
# Kernel Configuration
# Kernel settings and modules:
# - Kernel packages
# - Modules configuration
# - System control parameters
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
    boot = {
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
        ++ lib.optionals hostSystem.cfg.hardware.amdgpu.enable ["amdgpu"];
      kernel.sysctl = {
        "kernel.unprivileged_userns_clone" = 1; # Allow unprivileged processes to create user namespaces.
      };
      # AMD GPU kernel parameters (conditional)
      kernelParams = lib.mkIf hostSystem.cfg.hardware.amdgpu.enable [
        "amdgpu.ppfeaturemask=0xffffffff"
        "amdgpu.dpm=1"
      ];
    };
  };
}