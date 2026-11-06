{pkgs, ...}: {
  user.persist.files = [".npmrc"];
  environment.systemPackages = [pkgs.nodejs];
}
