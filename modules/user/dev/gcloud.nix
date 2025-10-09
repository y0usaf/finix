{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.dev.gcloud = {
    enable = lib.mkEnableOption "Google Cloud SDK (gcloud) CLI";
  };

  config = lib.mkIf config.user.dev.gcloud.enable {
    environment.systemPackages = [pkgs.google-cloud-sdk];
  };
}
