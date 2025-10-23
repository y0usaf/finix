{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.ui.wallust = {
    enable = lib.mkEnableOption "wallust color generation";
  };
  config = lib.mkIf config.user.ui.wallust.enable {
    environment.systemPackages = [
      pkgs.wallust
    ];
  };
}
