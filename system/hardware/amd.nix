###############################################################################
# AMD GPU Configuration Module
# - X server driver settings for AMD GPU
###############################################################################
{
  lib,
  hostSystem,
  ...
}: {
  config = {
    ###########################################################################
    # AMD GPU X Server Configuration (conditional)
    # X server driver settings for AMD GPU
    ###########################################################################
    services.xserver.videoDrivers = lib.mkIf hostSystem.hardware.amdgpu.enable ["amdgpu"];
  };
}
