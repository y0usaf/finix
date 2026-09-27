{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.gcloud = {
    enable = lib.mkEnableOption "Google Cloud SDK (gcloud) CLI";
  };

  config = lib.mkIf config.user.dev.gcloud.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/gcloud"
    ];
    environment.systemPackages = [pkgs.google-cloud-sdk];
  };
}
