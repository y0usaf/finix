{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.programs.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth user tools";
  };
  config = lib.mkIf config.home.programs.bluetooth.enable {
    environment.systemPackages = [
      pkgs.blueman
      pkgs.bluetuith
    ];
    usr = {
      files.".config/autostart/blueman.desktop" = {
        clobber = true;
        source = "${pkgs.blueman}/etc/xdg/autostart/blueman.desktop";
      };
    };
  };
}
