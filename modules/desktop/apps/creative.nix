{pkgs, ...}: {
  user.persist.directories = [".config/Pinta"];
  environment.systemPackages = [
    pkgs.pinta
    pkgs.gimp
  ];
}
