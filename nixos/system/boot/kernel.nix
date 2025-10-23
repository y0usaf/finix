{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      kernelModules =
        [
          "kvm-amd"
          "k10temp"
          "nct6775"
          "ashmem_linux"
          "binder_linux"
        ]
        ++ lib.optionals config.hardware.amdgpu.enable ["amdgpu"];
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
