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

  config = lib.mkIf config.services.docker.enable {
    virtualisation = {
      docker = {
        enable = true;
        enableOnBoot = true;
      };
      podman = {
        enable = true;
      };
    };
  };
}
