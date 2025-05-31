###############################################################################
# Graphics Configuration Module
# - General graphics settings
# - VAAPI and VDPAU packages
###############################################################################
{
  pkgs,
  ...
}: {
  config = {
    ###########################################################################
    # Graphics Settings
    # Configuration for graphics drivers and packages
    ###########################################################################
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };
}
