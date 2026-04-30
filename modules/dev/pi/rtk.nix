{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.dev.pi;
in {
  config = lib.mkIf (cfg.enable && cfg.rtk.enable) {
    environment.systemPackages = [
      pkgs.rtk
    ];
  };
}
