{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.programs.obs = {
    enable = lib.mkEnableOption "OBS Studio";
  };
  config = lib.mkIf config.user.programs.obs.enable {
    environment.systemPackages = [
      (pkgs.symlinkJoin {
        name = "obs-studio-with-cuda";
        paths = [
          (pkgs.wrapOBS {
            plugins = [
              pkgs.obs-studio-plugins.obs-backgroundremoval
              pkgs.obs-studio-plugins.obs-vkcapture
              pkgs.obs-studio-plugins.obs-pipewire-audio-capture
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
