{
  lib,
  flakeInputs,
  system,
  ...
} @ args: {
  imports = [
    ../../../nixos
    ./hardware-configuration.nix
    (flakeInputs.self + /configs/users/y0usaf.nix)
  ];

  fonts = {
    packages = [
      flakeInputs.fast-fonts.packages.${system}.default
    ];
    fontDir.enable = true;
  };
  hostname = "y0usaf-desktop";
  trustedUsers = ["y0usaf"];
  homeDirectory = "/home/y0usaf";
  stateVersion = "24.11";
  timezone = "America/Toronto";
  var-cache = true;
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
  };
  hardware.nvidia.management = {
    enable = true;
    maxClock = 2450;
    minClock = 300;
    coreVoltageOffset = -25;
    memoryVoltageOffset = -25;
    fanSpeed = 50;
  };
  user.gaming.proton.ntsync = true;
  services = {
    docker.enable = true;
    waydroid.enable = false;
    controllers.enable = true;
    tailscale.enableVPN = true;
    tftpd = {
      enable = true;
      path = "/srv/tftp";
    };
    syncthing-proxy = {
      enable = true;
      virtualHostName = "syncthing-desktop";
    };
    nginx = {
      enable = true;
      virtualHosts."pxe" = {
        listen = [
          {
            addr = "192.168.2.28";
            port = 8080;
          }
        ];
        root = "/srv/tftp";
        locations."/".extraConfig = "autoindex on;";
      };
    };
  };
}
