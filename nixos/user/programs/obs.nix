{
  config,
  pkgs,
  lib,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  options.user.programs.obs = {
    enable = lib.mkEnableOption "OBS Studio";
    backgroundRemoval.enable = lib.mkEnableOption "OBS background removal plugin";
  };
  config = lib.mkIf config.user.programs.obs.enable {
    environment.systemPackages = [
      (pkgs.symlinkJoin {
        name = "obs-studio-with-cuda";
        paths = [
          (pkgs.wrapOBS {
            plugins =
              lib.optional config.user.programs.obs.backgroundRemoval.enable
              pkgs.obs-studio-plugins.obs-backgroundremoval
              ++ [
                pkgs.obs-studio-plugins.obs-vkcapture
                pkgs.obs-studio-plugins.obs-pipewire-audio-capture
                pkgs.obs-studio-plugins.obs-aitum-multistream
                pkgs.obs-studio-plugins.obs-vertical-canvas
                pkgs.obs-studio-plugins.obs-scale-to-sound
                flakeInputs.obs-image-reaction.outputs.packages.${system}.default
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
