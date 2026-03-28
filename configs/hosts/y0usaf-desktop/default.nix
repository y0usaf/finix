{
  lib,
  flakeInputs,
  system,
  ...
}: {
  imports = [
    ../../../nixos
    ./hardware-configuration.nix
    (flakeInputs.self + /configs/users/y0usaf.nix)
  ];

  fonts = {
    packages = [
      flakeInputs.fast-fonts.packages."${system}".default
    ];
    fontDir.enable = true;
  };
  hostname = "y0usaf-desktop";
  trustedUsers = ["y0usaf"];
  homeDirectory = "/home/y0usaf";
  stateVersion = "24.11";
  timezone = "America/Toronto";
  var-cache = true;
  nixpkgs.config.cudaSupport = true;

  hardware = {
    bluetooth = {
      enable = true;
    };
    cpu.amd.enable = true;
    nvidia = {
      enable = true;
      cuda.enable = true;
    };
    amdgpu.enable = false;
    display.outputs =
      (lib.genAttrs ["DP-1" "DP-2" "DP-3" "DP-4"] (_: {mode = "5120x1440@239.76";}))
      // {
        "eDP-1" = {
          mode = "1920x1080@300.00";
        };
      };
  };
  user.gaming = {
    proton = {
      enable = true;
      nativeWayland = false;
    };
    mangohud = {
      enable = true;
      enableSessionWide = true;
      refreshRate = 175;
    };
    bg3 = {
      enable = true;
      scriptExtender.enable = true;
      nativeModLoader.enable = true;
      wasd.enable = true;
      nativeCameraTweaks.enable = true;
    };
  };
  hardware.nvidia.management = {
    enable = true;
    maxClock = 2450;
    minClock = 1000;
    coreVoltageOffset = -100;
    memoryVoltageOffset = -100;
    fanCurve = [
      {
        temp = 50;
        speed = 0;
      }
      {
        temp = 75;
        speed = 50;
      }
      {
        temp = 90;
        speed = 70;
      }
    ];
  };
  user.gaming.proton.ntsync = true;
  services = {
    btrbk-snapshots.enable = true;
    docker.enable = true;
    waydroid.enable = false;
    controllers.enable = true;
    tailscale.enableVPN = true;
    syncthing-proxy = {
      enable = true;
      virtualHostName = "syncthing-desktop";
    };
    nginx = {
      enable = true;
    };
  };

  services.openssh.ports = [2222];
  networking.firewall.allowedTCPPorts = [25565 2222];

  boot.windowsDualBoot = {
    enable = true;
    windowsEfiPartuuid = "09d3f11d-33f2-442b-9971-c279ef51860f";
  };
}
