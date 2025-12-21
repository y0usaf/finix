{
  config,
  lib,
  ...
}: {
  options.user.gaming.rv-there-yet.gameusersettings = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable RV There Yet GameUserSettings.ini configuration";
    };
  };
  config = lib.mkIf config.user.gaming.rv-there-yet.gameusersettings.enable {
    usr.files."${lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam.path}/steamapps/compatdata/3949040/pfx/drive_c/users/steamuser/AppData/Local/Ride/Saved/Config/Windows/GameUserSettings.ini" = {
      clobber = true;
      generator = lib.generators.toINI {};
      value = {
        "Internationalization" = {
          Culture = "en";
        };
        "ScalabilityGroups" = {
          "sg.ResolutionQuality" = "100";
          "sg.ViewDistanceQuality" = "3";
          "sg.AntiAliasingQuality" = "0";
          "sg.ShadowQuality" = "3";
          "sg.GlobalIlluminationQuality" = "3";
          "sg.ReflectionQuality" = "3";
          "sg.PostProcessQuality" = "3";
          "sg.TextureQuality" = "3";
          "sg.EffectsQuality" = "3";
          "sg.FoliageQuality" = "3";
          "sg.ShadingQuality" = "3";
          "sg.LandscapeQuality" = "3";
        };
        "/Script/Ride.RGGameUserSettings" = {
          bHasAutodetectedDLSS = "True";
          SoundMasterVolume = "0.400000";
          SoundAmbientVolume = "1.000000";
          SoundMusicVolume = "0.700000";
          SoundEffectsVolume = "1.000000";
          SoundUIVolume = "1.000000";
          SoundVOIPVolume = "1.000000";
          NumAutosaveSlots = "3";
          AutosaveIntervalMinutes = "30";
          DepthOfFieldEnabled = "True";
          aaMethod = "0";
          DidSetupFirstTime = "True";
          bDLSSEnabled = "False";
          bDLSSRREnabled = "False";
          DLSSMode = "DLAA";
          MaxFPS = "300";
          bLumenEnabled = "False";
          bDisableSceneCaptureComponents = "False";
          bHeadBobEnabled = "True";
          FOV = "110";
          VOIPMode = "EVOIPM_ToggleToTalk";
          SilenceDetectionAttackTime = "2.000000";
          SilenceDetectionReleaseTime = "1100.000000";
          SilenceDetectionThreshold = "0.020000";
          MicInputGain = "0.000000";
          JitterBufferDelay = "300.000000";
          MicNoiseGateThreshold = "0.030000";
          MicNoiseAttackTime = "40.000000";
          MicNoiseReleaseTime = "366.300018";
          "MouseSensitivity" = "(X=1.000000,Y=1.000000)";
          "ClutchSensitivity" = "(X=1.000000,Y=1.000000)";
          bInvertLook = "False";
          bHasInitialSetAllowSceneCapture = "True";
          bUseVSync = "False";
          bUseDynamicResolution = "False";
          ResolutionSizeX = "2543";
          ResolutionSizeY = "1418";
          LastUserConfirmedResolutionSizeX = "2543";
          LastUserConfirmedResolutionSizeY = "1418";
          FullscreenMode = "2";
          LastConfirmedFullscreenMode = "2";
          PreferredFullscreenMode = "1";
          Version = "5";
          AudioQualityLevel = "0";
          LastConfirmedAudioQualityLevel = "0";
          FrameRateLimit = "0.000000";
          DesiredScreenWidth = "2560";
          DesiredScreenHeight = "1440";
          LastUserConfirmedDesiredScreenWidth = "2560";
          LastUserConfirmedDesiredScreenHeight = "1440";
          LastRecommendedScreenWidth = "-1.000000";
          LastRecommendedScreenHeight = "-1.000000";
          LastCPUBenchmarkResult = "-1.000000";
          LastGPUBenchmarkResult = "-1.000000";
          LastGPUBenchmarkMultiplier = "1.000000";
          bUseHDRDisplayOutput = "False";
          HDRDisplayOutputNits = "1000";
        };
        "/Script/Engine.GameUserSettings" = {
          bUseDesiredScreenHeight = "False";
        };
      };
    };
  };
}
