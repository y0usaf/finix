{
  lib,
  pkgs,
  hostConfig,
  ...
}: {
  config = {
    boot = {
      kernelPackages = pkgs.linuxPackages_latest; # TODO: Re-enable linuxPackages_cachyos when chaotic is fixed
      kernelModules =
        [
          "kvm-amd"
          "k10temp"
          "nct6775"
          "ashmem_linux"
          "binder_linux"
        ]
        ++ lib.optionals hostConfig.hardware.amdgpu.enable ["amdgpu"];
      kernel.sysctl = {
        "kernel.unprivileged_userns_clone" = 1;
      };
      kernelParams = lib.mkIf hostConfig.hardware.amdgpu.enable [
        "amdgpu.ppfeaturemask=0xffffffff"
        "amdgpu.dpm=1"
      ];
    };
  };
}
