{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.programs.mpv = {
    enable = lib.mkEnableOption "mpv media player";
  };
  config = lib.mkIf config.home.programs.mpv.enable {
    environment.systemPackages = [pkgs.mpv];
  };
}
