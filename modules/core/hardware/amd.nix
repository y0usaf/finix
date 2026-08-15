{
  lib,
  ...
}: {
  # AMD CPU option. NOTE: hardware.amdgpu.enable was declared here but is now
  # owned by finix (finixSystem.nix stubs it with default true); the duplicate
  # declaration was removed so the raw import no longer errors. The kernel
  # module / microcode / xserver config gated on these options was NixOS-only
  # (boot.hardware & services) and is dropped by the compat shim.
  options.hardware.cpu.amd = {
    enable = lib.mkEnableOption "AMD CPU specific kernel tweaks";
    extraKernelModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["zenpower" "nct6775"];
      description = "Additional kernel modules to load when AMD CPU support is enabled.";
    };
  };
}