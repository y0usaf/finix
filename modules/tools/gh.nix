{
  config,
  lib,
  pkgs,
  ...
}: {
  user.persist.directories = [".config/gh"];
  environment.systemPackages = [pkgs.gh];

  user.files.".config/gh/config.yml" = {
    generator = lib.generators.toYAML {};
    value = {
      version = "1";
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };
}
