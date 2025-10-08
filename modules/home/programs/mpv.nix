{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.mpv;
in {
  options.home.programs.mpv = {
    enable = lib.mkEnableOption "mpv media player";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.mpv];
  };
}
