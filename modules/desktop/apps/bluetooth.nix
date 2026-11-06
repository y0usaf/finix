{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.blueman
    pkgs.bluetuith
  ];
  user.files.".config/autostart/blueman.desktop".source = "${pkgs.blueman}/etc/xdg/autostart/blueman.desktop";
}
