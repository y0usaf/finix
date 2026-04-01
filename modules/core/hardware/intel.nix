{
  config,
  lib,
  ...
}: {
  options.hardware.cpu.intel = {
    enable = lib.mkEnableOption "Intel CPU specific kernel tweaks";
    extraKernelModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["intel_pmc_core"];
      description = "Additional kernel modules to load when Intel CPU support is enabled.";
    };
  };

  config = lib.mkIf config.hardware.cpu.intel.enable {
    boot.kernelModules =
      [
        "kvm-intel"
        "coretemp"
      ]
      ++ config.hardware.cpu.intel.extraKernelModules;

    hardware.cpu.intel.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
