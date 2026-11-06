{
  config,
  lib,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.directories = ["/var/lib/docker"];
  environment.systemPackages = [
    pkgs.docker-buildx
    pkgs.docker-credential-helpers
  ];
  user.files.".config/docker/config.json" = {
    generator = lib.generators.toJSON {};
    value = {
      credsStore = "pass";
      currentContext = "default";
      plugins = {};
    };
  };
}
