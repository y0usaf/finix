{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.dualsensectl
  ];
}
