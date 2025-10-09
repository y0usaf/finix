{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.gaming.controllers = {
    enable = lib.mkEnableOption "gaming controller support";
  };
  config = lib.mkIf config.user.gaming.controllers.enable {
    environment.systemPackages = [
      pkgs.dualsensectl
    ];
  };
}
