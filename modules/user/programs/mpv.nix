{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.mpv = {
    enable = lib.mkEnableOption "mpv media player";
  };
  config = lib.mkIf config.user.programs.mpv.enable {
    environment.systemPackages = [pkgs.mpv];
  };
}
