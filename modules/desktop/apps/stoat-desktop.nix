{pkgs, ...}: {
  user.persist.directories = [".config/stoat-desktop"];
  environment.systemPackages = [pkgs.stoat-desktop];
}
