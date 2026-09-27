{
  config,
  pkgs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/gcloud"
  ];
  environment.systemPackages = [pkgs.google-cloud-sdk];
}
