# Hardware:
# - CPU: AMD Ryzen 9 7950X (16C/32T)
# - RAM: 96GB
# - Storage: 2× 3.6TB NVMe
# - GPU: RTX 4090 + Raphael iGPU
{
  lib,
  flakeInputs,
  system,
  ...
}: {
  imports = [
    ../../../modules/system
    ./hardware-configuration.nix
    ../../users/y0usaf
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
  services = {
    docker.enable = true;
    waydroid.enable = false;
    controllers.enable = true;
    tailscale.enableVPN = true;
    tftpd = {
      enable = true;
      path = "/srv/tftp";
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
      virtualHosts."syncthing-desktop" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8384";
          proxyWebsockets = true;
        };
      };
    };
  };
}
