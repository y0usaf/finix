{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.work.aws-cli.enable = lib.mkEnableOption "AWS CLI";

  config = lib.mkIf config.user.dev.work.aws-cli.enable {
    environment.systemPackages = [pkgs.awscli2];
  };
}
