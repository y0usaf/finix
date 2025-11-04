{lib, ...}: {
  imports = [
    ../../../nixos
    ./hardware-configuration.nix
    ../../users/server
  ];

  hostname = "y0usaf-server";
  trustedUsers = ["y0usaf"];
  homeDirectory = "/home/y0usaf";
  stateVersion = "24.11";
  timezone = "America/Toronto";
  var-cache = true;
  hardware = {
    bluetooth = {
      enable = false;
    };
    cpu.intel.enable = true;
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
    mediamtx.enable = true;
    n8n = {
      enable = true;
      openFirewall = true;
    };
    forgejo.enable = true;
    openssh.enable = lib.mkForce true;
    tailscale.enableVPN = true;
    syncthing-proxy = {
      enable = true;
      virtualHostName = "syncthing-server";
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22 80 443 2222 3000 22000];
    allowedUDPPorts = [22000 21027];
  };
}
