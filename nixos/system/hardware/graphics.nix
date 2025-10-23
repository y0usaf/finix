{pkgs, ...}: {
  config = {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [
        pkgs.vaapiVdpau
        pkgs.libvdpau-va-gl
      ];
    };
  };
}
