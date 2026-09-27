{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.work.gws.enable = lib.mkEnableOption "Google Workspace CLI";

  config = lib.mkIf config.user.dev.work.gws.enable {
    environment.systemPackages = [pkgs.gws];
  };
}
