{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.bluez
    pkgs.bluez-tools
  ];
}
