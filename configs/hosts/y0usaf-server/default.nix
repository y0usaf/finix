{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../../modules/system
    ./hardware-configuration.nix
    ../../users/server
  ];

  hostname = "y0usaf-server";
  trustedUsers = ["y0usaf"];
  homeDirectory = "/home/y0usaf";
  stateVersion = "24.11";
  timezone = "America/Toronto";
  profile = "default";
  var-cache = true;
  hardware = {
    bluetooth = {
      enable = false;
    };
    nvidia = {
      enable = false;
      cuda.enable = false;
    };
    amdgpu.enable = false;
  };
  services = {
    docker.enable = true;
    waydroid.enable = false;
    controllers.enable = false;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22];
  };

  systemd.services.sshd = {
    wantedBy = lib.mkForce ["multi-user.target"];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
