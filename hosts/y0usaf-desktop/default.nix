_: {
  imports = [
    ../../../modules/system
    ./hardware-configuration.nix
  ];
  users = ["y0usaf" "guest"];
  hostname = "y0usaf-desktop";
  homeDirectory = "/home/y0usaf";
  stateVersion = "24.11";
  timezone = "America/Toronto";
  profile = "default";
  hardware = {
    bluetooth = {
      enable = true;
    };
    nvidia = {
      enable = true;
      cuda.enable = true;
    };
    amdgpu.enable = false;
    display.outputs = {
      "DP-4" = {
        mode = "5120x1440@239.76";
      };
      "DP-3" = {
        mode = "5120x1440@239.76";
      };
      "DP-2" = {
        mode = "5120x1440@239.76";
      };
      "DP-1" = {
        mode = "5120x1440@239.76";
      };
      "eDP-1" = {
        mode = "1920x1080@300.00";
      };
    };
  };
  services = {
    docker.enable = true;
    waydroid.enable = false;
    controllers.enable = true;
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
    };
  };

  virtualisation = {
    qemu.enable = false;
  };
}
