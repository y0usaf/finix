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
    hjem.users.${config.user.name}.packages = with pkgs; [
      pulsemixer
      ffmpeg
      vlc
      stremio
      cmus
    ];
  };
}
