{ config, lib, pkgs, ... }:
{
  boot = {
    kernelModules = ["v4l2loopback"];
    extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
    extraModprobeConfig = ''
      # exclusive_caps: Chromium, Electron, etc. will only show device when actually streaming
      options v4l2loopback exclusive_caps=1
    '';
  };

  # Udev rule for correct permissions
  services.udev.extraRules = ''
    KERNEL=="video[0-9]*", GROUP="video", MODE="0660"
  '';

  # Polkit is required for some desktop/portal integrations
  security.polkit.enable = true;
}
