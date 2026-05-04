{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth user tools";
  };
  config = lib.mkIf config.user.programs.bluetooth.enable {
    environment.systemPackages = [
      pkgs.blueman
      pkgs.bluetuith
    ];
    manzil.users."${config.user.name}".files.".config/autostart/blueman.desktop" = {
      source = "${pkgs.blueman}/etc/xdg/autostart/blueman.desktop";
    };
  };
}
