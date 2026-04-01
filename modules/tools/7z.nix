{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.tools."7z" = {
    enable = lib.mkEnableOption "7z (p7zip) archive manager";
  };
  config = lib.mkIf config.user.tools."7z".enable {
    environment.systemPackages = [
      pkgs.p7zip
    ];
  };
}
