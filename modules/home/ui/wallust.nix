{
  config,
  pkgs,
  lib,
  ...
}: {
  options.home.ui.wallust = {
    enable = lib.mkEnableOption "wallust color generation";
  };
  config = lib.mkIf config.home.ui.wallust.enable {
    environment.systemPackages = [
      pkgs.wallust
    ];
  };
}
