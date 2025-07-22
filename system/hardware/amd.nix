{
  lib,
  hostSystem,
  ...
}: {
  config = {
    services.xserver.videoDrivers = lib.mkIf hostSystem.hardware.amdgpu.enable ["amdgpu"];
  };
}
