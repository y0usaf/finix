{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.programs.media;
in {
  options.home.programs.media = {
    enable = lib.mkEnableOption "media applications";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.pulsemixer
      pkgs.ffmpeg
      pkgs.vlc
      pkgs.stremio
      pkgs.cmus
    ];
  };
}
