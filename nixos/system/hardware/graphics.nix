{pkgs, ...}: {
  config = {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [
        pkgs.libva-vdpau-driver
        pkgs.libvdpau-va-gl
      ];
    };
  };
}
