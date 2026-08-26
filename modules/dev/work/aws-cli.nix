{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.work.aws-cli = {
    enable = lib.mkEnableOption "AWS CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.awscli2;
      description = "AWS CLI package to install.";
    };
  };

  config = lib.mkIf config.user.dev.work.aws-cli.enable {
    environment.systemPackages = [
      config.user.dev.work.aws-cli.package
    ];
  };
}
