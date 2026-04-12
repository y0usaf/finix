{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.media = {
    enable = lib.mkEnableOption "media applications";
  };
  config = lib.mkIf config.user.programs.media.enable {
    environment.systemPackages = [
      pkgs.ffmpeg
      pkgs.vlc
      pkgs.cmus
    ];
  };
}
