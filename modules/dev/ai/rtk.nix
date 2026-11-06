{pkgs, ...}: {
  user.persist.directories = [".local/share/rtk"];
  environment.systemPackages = [pkgs.rtk];
}
