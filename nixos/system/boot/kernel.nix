{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      kernelModules = [
        "ashmem_linux"
        "binder_linux"
      ];
      kernel.sysctl = {
        "kernel.unprivileged_userns_clone" = 1;
      };
      kernelParams = lib.mkIf config.hardware.amdgpu.enable [
        "amdgpu.ppfeaturemask=0xffffffff"
        "amdgpu.dpm=1"
      ];
    };
  };
}
