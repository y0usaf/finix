###############################################################################
# Container Virtualization Configuration
# Docker and Podman container engines:
# - Docker daemon
# - Podman container engine
###############################################################################
{
  lib,
  hostHome,
  ...
}: {
  config = {
    ###########################################################################
    # Container Virtualization
    # Docker and Podman container engines
    ###########################################################################
    virtualisation = {
      lxd.enable = true; # Enable LXD container hypervisor.
      docker = lib.mkIf hostHome.cfg.dev.docker.enable {
        enable = true; # Enable Docker daemon
        enableOnBoot = true; # Start Docker on boot
      };
      podman = lib.mkIf hostHome.cfg.dev.docker.enable {
        enable = true;
      };
    };
  };
}
