{
  lib,
  ...
}: {
  # Intel CPU option. kernel module / microcode config was NixOS-only
  # (boot.hardware) and is dropped by the compat shim; finix handles the
  # microcode pin natively (hosts/.../finix/boot.nix).
  options.hardware.cpu.intel = {
    enable = lib.mkEnableOption "Intel CPU specific kernel tweaks";
    extraKernelModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["intel_pmc_core"];
      description = "Additional kernel modules to load when Intel CPU support is enabled.";
    };
  };
}