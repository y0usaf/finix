{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.tools."7z";
in {
  options.home.tools."7z" = {
    enable = lib.mkEnableOption "7z (p7zip) archive manager";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.p7zip
    ];
  };
}
