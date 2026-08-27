{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) dev;
in {
  options.user.dev.rtk = {
    enable = lib.mkEnableOption "rtk binary";
  };

  config = lib.mkIf dev.rtk.enable {
    environment.systemPackages = [
      pkgs.rtk
    ];
  };
}
