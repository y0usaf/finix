{ lib, ... }: {
  # Boot-only variant: do not activate this configuration on a live desktop.
  # Kernel-level blocking also covers explicit modprobe calls and udev aliases.
  specialisation.vbios-maintenance = {
    hardware.nvidia.enable = lib.mkForce false;
    user.ui.cudaterm.enable = lib.mkForce false;
    user.defaults.terminal = lib.mkForce "xterm";
    boot.kernelParams = lib.mkAfter [
      "module_blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm,nouveau"
      "modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm,nouveau"
      "vbios_maintenance=1"
    ];
    boot.kernelModules = lib.mkAfter ["amdgpu"];
    environment.etc."vbios-maintenance".text = ''
      VBIOS maintenance: NVIDIA drivers are blocked; use motherboard graphics.
      No firmware operation runs automatically. Recovery files:
      /home/y0usaf/Documents/hw/vbios-restoration-2026-09-06
    '';
  };
}
