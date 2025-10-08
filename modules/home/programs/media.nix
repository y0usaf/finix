{
  config,
  pkgs,
  lib,
  ...
}: {
  options.home.programs.media = {
    enable = lib.mkEnableOption "media applications";
  };
  config = lib.mkIf config.home.programs.media.enable {
    environment.systemPackages = [
      pkgs.pulsemixer
      pkgs.ffmpeg
      pkgs.vlc
      pkgs.stremio
      pkgs.cmus
    ];
  };
}
