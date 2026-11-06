{pkgs, ...}: {
  user.persist.directories = [
    ".config/gws"
    ".config/gws-inscend"
  ];
  environment.systemPackages = [pkgs.gws];
}
