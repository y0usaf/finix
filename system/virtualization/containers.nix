###############################################################################
# Container Virtualization Configuration
# Docker and Podman container engines:
# - Docker daemon
# - Podman container engine
# - Docker user group management
###############################################################################
{
  lib,
  config,
  hostHome,
  ...
}: let
  dockerEnabled = hostHome.cfg.dev.docker.enable or false;
in {
  config = {
    ###########################################################################
    # Container Virtualization
    # Docker and Podman container engines
    ###########################################################################
    virtualisation = {
      lxd.enable = true; # Enable LXD container hypervisor.
      docker = lib.mkIf dockerEnabled {
        enable = true; # Enable Docker daemon
        enableOnBoot = true; # Start Docker on boot
      };
      podman = lib.mkIf dockerEnabled {
        enable = true;
      };
    };

    ###########################################################################
    # Docker User Group Management
    # Automatically add user to docker group when docker is enabled
    ###########################################################################
    users.users.${config.cfg.shared.username} = lib.mkIf dockerEnabled {
      extraGroups = ["docker"];
    };
  };
}
