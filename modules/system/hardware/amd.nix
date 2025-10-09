{
  config,
  lib,
  ...
}: {
  options.hardware.amdgpu.enable = lib.mkEnableOption "AMD GPU support";

  config = {
    services.xserver.videoDrivers = lib.mkIf config.hardware.amdgpu.enable ["amdgpu"];
  };
}
