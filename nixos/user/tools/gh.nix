{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.tools.gh.enable = lib.mkEnableOption "GitHub CLI";

  config = lib.mkIf config.user.tools.gh.enable {
    environment.systemPackages = [pkgs.gh];

    usr.files.".config/gh/config.yml" = {
      generator = lib.generators.toYAML {};
      value = {
        version = "1";
        git_protocol = "ssh";
        prompt = "enabled";
      };
    };
  };
}
