{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".aws"
    ".config/aws"
  ];
  environment.systemPackages = [pkgs.awscli2];
}
