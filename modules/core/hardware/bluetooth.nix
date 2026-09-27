{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.bluez-tools
  ];
}
