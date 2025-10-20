# Hardware:
# - CPU: Intel N100 (4C/4T)
# - RAM: 16GB
# - Storage: 477GB SSD
# - GPU: None (headless)
{lib, ...}: {
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
    n8n = {
      enable = true;
      openFirewall = true;
    };
    forgejo.enable = true;
    openssh.enable = lib.mkForce true;
    tailscale.enableVPN = true;
    nginx-reverse-proxy = true;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22 80 443 2222 3000 22000]; # SSH, HTTP, HTTPS, Forgejo SSH, Forgejo HTTP, and Syncthing
    allowedUDPPorts = [22000 21027]; # Syncthing sync and discovery
  };
}
