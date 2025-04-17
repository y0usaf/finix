{ config, lib, pkgs, ... }:
{
  # Load v4l2loopback at boot
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];

  # Set v4l2loopback options for OBS compatibility
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  # Udev rule for correct permissions
  services.udev.extraRules = ''
    KERNEL=="video[0-9]*", GROUP="video", MODE="0660"
  '';

  # Polkit is required for some desktop/portal integrations
  security.polkit.enable = true;
}
