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
    environment.systemPackages = [
      (pkgs.symlinkJoin {
        name = "obs-studio-with-cuda";
        paths = [
          (pkgs.wrapOBS {
            plugins = [
              pkgs.obs-studio-plugins.obs-backgroundremoval
              pkgs.obs-studio-plugins.obs-vkcapture
              pkgs.obs-studio-plugins.obs-pipewire-audio-capture
              pkgs.obs-studio-plugins.obs-image-reaction
              pkgs.obs-studio-plugins.obs-aitum-multistream
              pkgs.obs-studio-plugins.obs-vertical-canvas
              pkgs.obs-studio-plugins.obs-scale-to-sound
            ];
          })
        ];
        buildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/obs \
            --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib:/run/opengl-driver-32/lib
        '';
      })
      pkgs.v4l-utils
    ];
  };
}
