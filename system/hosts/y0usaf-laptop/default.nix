# SYSTEM CONFIGURATION for y0usaf-laptop
{pkgs, ...}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
in {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix # Re-enable with fixed config
  ];

  cfg = {
    system = {
      username = username;
      homeDirectory = homeDir;
      hostname = "y0usaf-laptop";
      stateVersion = "24.11";
      timezone = "America/Toronto";
      config = "default";
    };
    hardware = {
      bluetooth = {
        enable = true;
      };
      nvidia.enable = false;
      amdgpu.enable = true;
    };
    core = {
      ssh.enable = true;
      xdg.enable = true;
      zsh = {
        enable = true;
        cat-fetch = true;
        history-memory = 10000;
        history-storage = 10000;
        zellij.enable = true;
      };
      env = {
        enable = true;
        tokenDir = "${homeDir}/Tokens";
      };
      systemd = {
        enable = true;
        autoFormatNix = {
          enable = true;
          directory = "${homeDir}/nixos";
        };
      };
    };
  };

  # Ensure display manager is properly configured
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
  };

  # AMD GPU specific configuration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  users.users.${username}.extraGroups = ["docker"];
}
