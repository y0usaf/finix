{
  config,
  lib,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.directories = [
    "/var/lib/docker"
  ];
  environment.systemPackages = [
    pkgs.docker-buildx
    pkgs.docker-credential-helpers
  ];
  manzil.users."${config.user.name}".files.".config/docker/config.json" = {
    generator = lib.generators.toJSON {};
    value = {
      credsStore = "pass";
      currentContext = "default";
      plugins = {};
    };
  };
}
