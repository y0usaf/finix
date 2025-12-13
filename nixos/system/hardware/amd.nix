{
  config,
  lib,
  ...
}: {
  options = {
    hardware.cpu.amd = {
      enable = lib.mkEnableOption "AMD CPU specific kernel tweaks";
      extraKernelModules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["zenpower" "nct6775"];
        description = "Additional kernel modules to load when AMD CPU support is enabled.";
      };
    };

    hardware.amdgpu.enable = lib.mkEnableOption "AMD GPU support";
  };

  config = lib.mkMerge [
    (lib.mkIf config.hardware.cpu.amd.enable {
      boot.kernelModules =
        [
          "kvm-amd"
          "k10temp"
        ]
        ++ config.hardware.cpu.amd.extraKernelModules;

      hardware.cpu.amd.updateMicrocode =
        lib.mkDefault config.hardware.enableRedistributableFirmware;
    })

    (lib.mkIf config.hardware.amdgpu.enable {
      services.xserver.videoDrivers = ["amdgpu"];
      nixpkgs.config.hipSupport = true;
    })
  ];
}
