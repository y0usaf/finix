{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.file-roller
  ];
}
