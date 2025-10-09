{
  config,
  lib,
  ...
}: {
  options.services.docker = lib.mkOption {
    type = lib.types.submodule {
      options.enable = lib.mkEnableOption "Docker and Podman container support";
    };
    default = {};
  };

  config = {
    virtualisation = {
      docker = lib.mkIf config.services.docker.enable {
        enable = true;
        enableOnBoot = true;
      };
      podman = lib.mkIf config.services.docker.enable {
        enable = true;
      };
    };
  };
}
