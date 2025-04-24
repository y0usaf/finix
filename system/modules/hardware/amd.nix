###############################################################################
# AMD GPU Configuration Module
# - X server driver settings for AMD GPU
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}: {
  config = {
    ###########################################################################
    # AMD GPU X Server Configuration (conditional)
    # X server driver settings for AMD GPU
    ###########################################################################
    services.xserver.videoDrivers = lib.mkIf hostSystem.cfg.hardware.amdgpu.enable ["amdgpu"];
  };
}
