{
  lib,
  config,
  hostSystem,
  ...
}: {
  config = {
    virtualisation = {
      lxd.enable = true;
      docker = lib.mkIf (hostSystem.services.docker.enable or false) {
        enable = true;
        enableOnBoot = true;
      };
      podman = lib.mkIf (hostSystem.services.docker.enable or false) {
        enable = true;
      };
    };
  };
}
