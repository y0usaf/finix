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
        # Socket activation: daemon (and any unless-stopped containers,
        # e.g. supabase local stacks) only come up on first docker command.
        enableOnBoot = false;
      };
      podman.enable = true;
    };
  };
}
