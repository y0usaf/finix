{
  config,
  lib,
  ...
}: {
  options.user.gaming.wukong = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Black Myth: Wukong configuration";
    };
  };
  config = lib.mkIf config.user.gaming.wukong.enable {
    usr.files."${lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam.path}/steamapps/compatdata/2358720/pfx/drive_c/users/steamuser/AppData/Local/b1/Saved/Config/Windows/Engine.ini" = {
      clobber = true;
      generator = lib.generators.toINI {};
      value = {
        "SystemSettings" = {
          "r.DefaultFeature.AntiAliasing" = "0";
          "pp.VignetteIntensity" = "0.0";
          "r.SceneColorFringeQuality" = "0";
          "r.SceneColorFringe.Max" = "0";
          "r.DepthOfFieldQuality" = "0";
          "r.DepthOfField.DepthBlur.Amount" = "0";
          "r.Tonemapper.GrainQuantization" = "0";
          "r.FilmGrain" = "0";
          "r.Tonemapper.Quality" = "0";
          "r.BloomQuality" = "0";
          "r.MotionBlurQuality" = "0";
          "r.AmbientOcclusionLevels" = "0";
          "r.AmbientOcclusionStaticFraction" = "0";
          "r.LensFlareQuality" = "0";
          "r.SSR.Quality" = "0";
          "r.Tonemapper.Sharpen" = "1.0";
          "r.Atmosphere" = "0";
          "r.VolumetricFog" = "0";
          "r.VolumetricFog.Quality" = "0";
          "r.EyeAdaptation.MethodOverride" = "0";
          "r.DefaultFeature.LensFlare" = "0";
          "r.DefaultFeature.Bloom" = "0";
          "r.DefaultFeature.AutoExposure" = "0";
          "r.PostProcessAAQuality" = "0";
          "r.SSS.Quality" = "0";
          "r.SSS.Scale" = "0";
          "r.ChromaticAberrationStartOffset" = "0";
        };
        "/Script/Engine.InputSettings" = {
          ConsoleKey = "Tilde";
        };
      };
    };
  };
}
