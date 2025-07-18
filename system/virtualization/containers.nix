###############################################################################
# Container Virtualization Configuration
# Docker and Podman container engines:
# - Docker daemon
# - Podman container engine
# - LXD container hypervisor
###############################################################################
{
  lib,
  config,
  hostSystem,
  ...
}: {
  config = {
    ###########################################################################
    # Container Virtualization
    # Services enabled based on host capability declarations
    ###########################################################################
    virtualisation = {
      lxd.enable = true; # Enable LXD container hypervisor
      
      docker = lib.mkIf (hostSystem.services.docker.enable or false) {
        enable = true; # Enable Docker daemon
        enableOnBoot = true; # Start Docker on boot
      };
      
      podman = lib.mkIf (hostSystem.services.docker.enable or false) {
        enable = true; # Enable Podman as Docker alternative
      };
    };
  };
}
