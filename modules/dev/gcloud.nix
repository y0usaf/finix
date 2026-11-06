{pkgs, ...}: {
  user.persist.directories = [".config/gcloud"];
  environment.systemPackages = [pkgs.google-cloud-sdk];
}
