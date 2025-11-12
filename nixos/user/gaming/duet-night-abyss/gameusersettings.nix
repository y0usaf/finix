{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.gaming.duet-night-abyss.enable {
    usr.files."${lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam.path}/steamapps/compatdata/3286820662/pfx/drive_c/Program Files (x86)/Duet Night Abyss/EMLauncher/Saved/Config/WindowsNoEditor/GameUserSettings.ini" = {
      clobber = true;
      generator = lib.generators.toINI {};
      value = {
        "Internationalization" = {
          Language = "en";
        };
        "ScalabilityGroups" = {
          "sg.ResolutionQuality" = "100.000000";
          "sg.ViewDistanceQuality" = "4";
          "sg.AntiAliasingQuality" = "0";
          "sg.ShadowQuality" = "4";
          "sg.PostProcessQuality" = "4";
          "sg.TextureQuality" = "4";
          "sg.EffectsQuality" = "4";
          "sg.FoliageQuality" = "4";
          "sg.ShadingQuality" = "4";
        };
        "/Script/Engine.GameUserSettings" = {
          bUseVSync = "False";
          bUseDynamicResolution = "False";
          ResolutionSizeX = "1344";
          ResolutionSizeY = "642";
          LastUserConfirmedResolutionSizeX = "1344";
          LastUserConfirmedResolutionSizeY = "642";
          WindowPosX = "-1";
          WindowPosY = "-1";
          FullscreenMode = "2";
          LastConfirmedFullscreenMode = "2";
          PreferredFullscreenMode = "1";
          Version = "5";
          AudioQualityLevel = "0";
          LastConfirmedAudioQualityLevel = "0";
          FrameRateLimit = "0.000000";
          DesiredScreenWidth = "1280";
          bUseDesiredScreenHeight = "False";
          DesiredScreenHeight = "720";
          LastUserConfirmedDesiredScreenWidth = "1280";
          LastUserConfirmedDesiredScreenHeight = "720";
          LastRecommendedScreenWidth = "-1.000000";
          LastRecommendedScreenHeight = "-1.000000";
          LastCPUBenchmarkResult = "-1.000000";
          LastGPUBenchmarkResult = "-1.000000";
          LastGPUBenchmarkMultiplier = "1.000000";
          bUseHDRDisplayOutput = "False";
          HDRDisplayOutputNits = "1000";
        };
        "ShaderPipelineCache.CacheFile" = {
          LastOpened = "EMLauncher";
        };
      };
    };
    usr.files."${lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam.path}/steamapps/compatdata/3286820662/pfx/drive_c/Program Files (x86)/Duet Night Abyss/DNA Game/EM/Saved/Config/WindowsNoEditor/GameUserSettings.ini" = {
      clobber = true;
      generator = lib.generators.toINI {};
      value = {
        "Internationalization" = {
          Language = "en";
        };
        "ScalabilityGroups" = {
          "sg.ResolutionQuality" = "100.000000";
          "sg.ViewDistanceQuality" = "4";
          "sg.AntiAliasingQuality" = "0";
          "sg.ShadowQuality" = "4";
          "sg.PostProcessQuality" = "4";
          "sg.TextureQuality" = "4";
          "sg.EffectsQuality" = "4";
          "sg.FoliageQuality" = "4";
          "sg.ShadingQuality" = "4";
        };
        "/Script/Engine.GameUserSettings" = {
          bUseVSync = "False";
          bUseDynamicResolution = "False";
          ResolutionSizeX = "2543";
          ResolutionSizeY = "1418";
          LastUserConfirmedResolutionSizeX = "2543";
          LastUserConfirmedResolutionSizeY = "1418";
          WindowPosX = "-1";
          WindowPosY = "-1";
          FullscreenMode = "2";
          LastConfirmedFullscreenMode = "2";
          PreferredFullscreenMode = "1";
          Version = "5";
          AudioQualityLevel = "0";
          LastConfirmedAudioQualityLevel = "0";
          FrameRateLimit = "0.000000";
          DesiredScreenWidth = "1280";
          bUseDesiredScreenHeight = "False";
          DesiredScreenHeight = "720";
          LastUserConfirmedDesiredScreenWidth = "1280";
          LastUserConfirmedDesiredScreenHeight = "720";
          LastRecommendedScreenWidth = "-1.000000";
          LastRecommendedScreenHeight = "-1.000000";
          LastCPUBenchmarkResult = "-1.000000";
          LastGPUBenchmarkResult = "-1.000000";
          LastGPUBenchmarkMultiplier = "1.000000";
          bUseHDRDisplayOutput = "False";
          HDRDisplayOutputNits = "1000";
        };
        "ShaderPipelineCache.CacheFile" = {
          LastOpened = "EM";
        };
      };
    };
  };
}
