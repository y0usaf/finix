{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.work.aws-cli.enable = lib.mkEnableOption "AWS CLI";

  config = lib.mkIf config.user.dev.work.aws-cli.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".aws"
      ".config/aws"
    ];
    environment.systemPackages = [pkgs.awscli2];
  };
}
