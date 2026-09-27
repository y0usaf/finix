{
  config,
  lib,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/gh"
  ];
  environment.systemPackages = [pkgs.gh];

  manzil.users."${config.user.name}".files.".config/gh/config.yml" = {
    generator = lib.generators.toYAML {};
    value = {
      version = "1";
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };
}
