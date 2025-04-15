{
  config,
  lib,
  pkgs,
  host,
  ...
}: {
  options.host.cfg.programs.bambu.enable = lib.mkEnableOption "Bambu Studio";

  config = lib.mkIf host.cfg.programs.bambu.enable {
    home.packages = [
      (pkgs.bambu-studio.overrideAttrs (oldAttrs: {
        version = "01.00.01.50";
        src = pkgs.fetchFromGitHub {
          owner = "bambulab";
          repo = "BambuStudio";
          rev = "v01.00.01.50";
          hash = "sha256-7mkrPl2CQSfc1lRjl1ilwxdYcK5iRU//QGKmdCicK30=";
        };
      }))
    ];
  };
}