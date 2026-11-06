{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.nicotine-plus
    pkgs.file-roller
    pkgs.p7zip
  ];
}
