# Phase-2a: NVIDIA proprietary driver + seat/dbus/udev groundwork.
# The session itself (niri/tomoe-session/pipewire) is phase-2b, gated on
# this driver lighting up on metal (lsmod nvidia, /dev/dri, /dev/nvidia*,
# console on nvidia-drm fbdev).
#
# Mirrors modules/core/hardware/nvidia.nix from the NixOS universe — the
# module universes cannot share code, keep the two in lockstep by hand.
# Upstream finix's hardware.nvidia module supplies: nouveau/nvidiafb
# blacklists, softdep nvidia_uvm, eager nvidia/nvidia_modeset/nvidia_drm
# load, nvidia-drm.modeset=1 + fbdev=1 (>=545), udev mknod + drm-node
# permission rules, egl external platforms, /run/opengl-driver wiring.
{
  config,
  lib,
  ...
}: {
  hardware.nvidia = {
    enable = true;
    kernelModule = "closed"; # NixOS side: hardware.nvidia.open = false
    modesetting.enable = true;
    # NixOS runs gsp.enable = false with the closed module — mirror it.
    gsp.enable = false;
    videoAcceleration = true;
  };

  # UPSTREAM GAP: finix's nvidia module sets extraModulePackages to
  # cfg.package.bin — stale vs current nixpkgs, which split the kernel
  # modules into cfg.package.mod (nvidia-kernel-modules-*). .bin carries no
  # lib/modules so it aggregates to nothing (silently — no eval error, no
  # nvidia.ko). Add .mod ourselves; the stale .bin entry stays harmless.
  boot.extraModulePackages = [config.hardware.nvidia.package.mod];

  # kernelParams parity with the NixOS module (its ibt=off / modeset /
  # fbdev params come from upstream finix's nvidia module itself).
  boot.kernelParams = [
    "nvidia.NVreg_UsePageAttributeTable=1"
    "nvidia.NVreg_EnableResizableBar=1"
    "nvidia.NVreg_RegistryDwords=RmEnableAggressiveVblank=1"
    "nvidia_modeset.disable_vrr_memclk_switch=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
  ];
}
