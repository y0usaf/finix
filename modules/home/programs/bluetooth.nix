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
    users.users.${config.user.name}.maid = {
      packages = with pkgs; [
        blueman
        bluetuith
      ];
      file.xdg_config."autostart/blueman.desktop".source = "${pkgs.blueman}/etc/xdg/autostart/blueman.desktop";
    };
  };
}
