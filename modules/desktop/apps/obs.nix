{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.programs.obs = {
    enable = lib.mkEnableOption "OBS Studio";
    backgroundRemoval.enable = lib.mkEnableOption "OBS background removal plugin";
  };
  config = lib.mkIf config.user.programs.obs.enable {
    boot = {
      kernelModules = ["v4l2loopback"];
      extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1
      '';
    };

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
                flakeInputs.obs-image-reaction.outputs.packages."${pkgs.stdenv.hostPlatform.system}".default
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
