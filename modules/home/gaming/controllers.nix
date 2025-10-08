{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.gaming.controllers = {
    enable = lib.mkEnableOption "gaming controller support";
  };
  config = lib.mkIf config.home.gaming.controllers.enable {
    environment.systemPackages = [
      pkgs.dualsensectl
    ];
  };
}
