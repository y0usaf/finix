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

  config = lib.mkMerge [
    (lib.mkIf dev.pi.enable {
      user.dev.rtk.enable = lib.mkDefault true;
    })

    (lib.mkIf dev.rtk.enable {
      environment.systemPackages = [
        pkgs.rtk
      ];
    })
  ];
}
