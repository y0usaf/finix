{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.programs.stremio = {
    enable = lib.mkEnableOption "Stremio media center";
  };
  config = lib.mkIf config.home.programs.stremio.enable {
    environment.systemPackages = [pkgs.stremio];
  };
}
