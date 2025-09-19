{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.dev.gcloud;
in {
  options.home.dev.gcloud = {
    enable = lib.mkEnableOption "Google Cloud SDK (gcloud) CLI";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.google-cloud-sdk];
  };
}
