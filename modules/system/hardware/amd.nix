{
  lib,
  hostConfig,
  ...
}: {
  config = {
    services.xserver.videoDrivers = lib.mkIf hostConfig.hardware.amdgpu.enable ["amdgpu"];
  };
}
