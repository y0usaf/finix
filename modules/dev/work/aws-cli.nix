{pkgs, ...}: {
  user.persist.directories = [
    ".aws"
    ".config/aws"
  ];
  environment.systemPackages = [pkgs.awscli2];
}
