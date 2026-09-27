{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.p7zip
  ];
}
