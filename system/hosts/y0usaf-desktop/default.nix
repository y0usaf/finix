# SYSTEM CONFIGURATION for y0usaf-desktop
{pkgs, ...}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
in {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  cfg = {
    system = {
      username = username;
      homeDirectory = homeDir;
      hostname = "y0usaf-desktop";
      stateVersion = "24.11";
      timezone = "America/Toronto";
      config = "default";
    };
    hardware = {
      bluetooth = {
        enable = true;
      };
      nvidia = {
        enable = true;
        cuda.enable = true;
      };
      amdgpu.enable = false;
    };
    core = {
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

  users.users.${username}.extraGroups = ["docker"];
}
