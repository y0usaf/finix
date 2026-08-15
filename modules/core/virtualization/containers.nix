{
  lib,
  ...
}: {
  # option declaration retained (harmless, keeps the surface finix passes
  # through); its virtualisation.docker/podman config was NixOS-only and is
  # dropped by the compat shim (docker/podman are deferred — see notes).
  options.services.docker = lib.mkOption {
    type = lib.types.submodule {
      options.enable = lib.mkEnableOption "Docker and Podman container support";
    };
    default = {};
  };
}