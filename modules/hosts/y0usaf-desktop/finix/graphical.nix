{
  config,
  lib,
  ...
}: {
  hardware.nvidia = {
    enable = true;
    kernelModule = "closed";
    modesetting.enable = true;
    gsp.enable = false;
    videoAcceleration = true;
  };

  boot.extraModulePackages = [config.hardware.nvidia.package.mod];

  boot.kernelParams = [
    "nvidia.NVreg_UsePageAttributeTable=1"
    "nvidia.NVreg_EnableResizableBar=1"
    "nvidia.NVreg_RegistryDwords=RmEnableAggressiveVblank=1"
    "nvidia_modeset.disable_vrr_memclk_switch=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
  ];
}
