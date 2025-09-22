{
  lib,
  hostConfig,
  ...
}: {
  config = {
    virtualisation = {
      docker = lib.mkIf (hostConfig.services.docker.enable or false) {
        enable = true;
        enableOnBoot = true;
      };
      podman = lib.mkIf (hostConfig.services.docker.enable or false) {
        enable = true;
      };
    };
  };
}
