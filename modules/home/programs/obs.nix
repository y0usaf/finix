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
    environment.systemPackages = with pkgs; [
      (symlinkJoin {
        name = "obs-studio-with-cuda";
        paths = [
          (wrapOBS {
            plugins = with obs-studio-plugins; [
              obs-backgroundremoval
              obs-vkcapture
              obs-pipewire-audio-capture
              obs-image-reaction
              obs-aitum-multistream
              obs-vertical-canvas
              obs-scale-to-sound
            ];
          })
        ];
        buildInputs = [makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/obs \
            --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib:/run/opengl-driver-32/lib
        '';
      })
      v4l-utils
    ];
  };
}
