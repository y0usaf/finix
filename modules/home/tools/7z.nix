{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.tools."7z" = {
    enable = lib.mkEnableOption "7z (p7zip) archive manager";
  };
  config = lib.mkIf config.home.tools."7z".enable {
    environment.systemPackages = [
      pkgs.p7zip
    ];
  };
}
