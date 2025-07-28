{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.bluetooth;
in {
  options.home.programs.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth user tools";
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        blueman
        bluetuith
      ];
      files.".config/autostart/blueman.desktop" = {
        clobber = true;
        source = "${pkgs.blueman}/etc/xdg/autostart/blueman.desktop";
      };
    };
  };
}
