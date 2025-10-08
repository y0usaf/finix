{
  config,
  pkgs,
  lib,
  ...
}: {
  options.home.dev.gcloud = {
    enable = lib.mkEnableOption "Google Cloud SDK (gcloud) CLI";
  };

  config = lib.mkIf config.home.dev.gcloud.enable {
    environment.systemPackages = [pkgs.google-cloud-sdk];
  };
}
