{pkgs, ...}: {
  environment.systemPackages = [pkgs.polkit_gnome];
}
