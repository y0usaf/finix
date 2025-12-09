{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.gaming.arc-raiders.enable {
    usr.files."${lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam.path}/steamapps/compatdata/1808500/pfx/drive_c/users/steamuser/AppData/Local/PioneerGame/Saved/Config/WindowsClient/GameUserSettings.ini" = {
      clobber = true;
      generator = lib.generators.toINI {};
      value = {
        "ScalabilityGroups" = {
          "sg.ResolutionQuality" = "100";
          "sg.ViewDistanceQuality" = "3";
          "sg.AntiAliasingQuality" = "3";
          "sg.ShadowQuality" = "3";
          "sg.GlobalIlluminationQuality" = "3";
          "sg.ReflectionQuality" = "3";
          "sg.PostProcessQuality" = "3";
          "sg.TextureQuality" = "3";
          "sg.EffectsQuality" = "3";
          "sg.FoliageQuality" = "3";
          "sg.ShadingQuality" = "3";
        };

        "/Script/EmbarkUserSettings.EmbarkGameUserSettings" = {
          "EmbarkVersion" = "6";
          "NvReflexMode" = "Enabled";
          "ReflexLatewarpMode" = "Off";
          "bAntiLag2Enabled" = "True";
          "DLSSFrameGenerationMode" = "On2X";
          "ResolutionScalingMethod" = "DLSS";
          "bResolutionScalingMethodSelectedByUser" = "False";
          "ResolutionScaleMode" = "Auto";
          "DLSSMode" = "Auto";
          "DLSSModel" = "Transformer";
          "FSR3Mode" = "Balanced";
          "FSR3FrameGenerationMode" = "Off";
          "XeSSMode" = "Quality";
          "SecondaryResolutionScalePercentage" = "100.000000";
          "bConsole120HzModeEnabled" = "False";
          "MotionBlurEnabled" = "False";
          "LensDistortionEnabled" = "False";
          "RTXGIQuality" = "Static";
          "RTXGIResolutionQuality" = "3";
          "bIdleEnergySavingEnabled" = "False";
          "bInactiveWindowEnergySavingEnabled" = "False";
          "PerformanceOverlayMode" = "Detailed";
          "bUseVSync" = "False";
          "bUseDynamicResolution" = "False";
          "ResolutionSizeX" = "5120";
          "ResolutionSizeY" = "1440";
          "WindowedResolutionSizeX" = "2543";
          "WindowedResolutionSizeY" = "1418";
          "FullscreenMode" = "1";
          "PreferredFullscreenMode" = "1";
          "Version" = "5";
          "AudioQualityLevel" = "0";
          "FrameRateLimit" = "0.000000";
          "DesiredScreenWidth" = "2560";
          "DesiredScreenHeight" = "1440";
          "bUseHDRDisplayOutput" = "False";
          "HDRDisplayOutputNits" = "1000";
        };

        "/Script/Engine.GameUserSettings" = {
          "bUseDesiredScreenHeight" = "False";
        };

        "Internationalization" = {
          "Culture" = "en";
        };
      };
    };
  };
}
