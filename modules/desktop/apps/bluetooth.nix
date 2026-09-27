{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    pkgs.blueman
    pkgs.bluetuith
  ];
  manzil.users."${config.user.name}".files.".config/autostart/blueman.desktop" = {
    source = "${pkgs.blueman}/etc/xdg/autostart/blueman.desktop";
  };
}
