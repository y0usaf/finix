###############################################################################
# Hardware Configuration Module
# Hardware-specific settings excluding NVIDIA (which has its own module):
# - Graphics configuration
# - I2C bus for hardware monitoring
# - AMD GPU configuration
###############################################################################
{
  config,
  lib,
  pkgs,
  profile,
  ...
}: {
  config = {
    ###########################################################################
    # Hardware-Specific Settings
    # Configuration for specific hardware drivers and graphics
    ###########################################################################
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          vaapiVdpau
          libvdpau-va-gl
        ];
      };

      i2c.enable = true;
    };

    ###########################################################################
    # AMD GPU X Server Configuration (conditional)
    # X server driver settings for AMD GPU
    ###########################################################################
    services.xserver.videoDrivers = lib.mkIf profile.cfg.core.amdgpu.enable ["amdgpu"];
  };
}
