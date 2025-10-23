{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.programs.media = {
    enable = lib.mkEnableOption "media applications";
  };
  config = lib.mkIf config.user.programs.media.enable {
    environment.systemPackages = [
      pkgs.pulsemixer
      pkgs.ffmpeg
      pkgs.vlc
      pkgs.stremio
      pkgs.cmus
    ];
  };
}
