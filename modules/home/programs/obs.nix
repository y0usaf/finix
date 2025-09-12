{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.programs.obs;
in {
  options.home.programs.obs = {
    enable = lib.mkEnableOption "OBS Studio";
  };
  config = lib.mkIf cfg.enable {
    usr.packages = with pkgs; [
      (wrapOBS {
        plugins = with obs-studio-plugins; [
          obs-backgroundremoval
          obs-vkcapture
          obs-pipewire-audio-capture
          obs-image-reaction
        ];
      })
      v4l-utils
    ];
  };
}
