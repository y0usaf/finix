{
  config,
  lib,
  ...
}: let
  cfg = config.home.gaming.clair-obscur.gameusersettings;
in {
  options.home.gaming.clair-obscur.gameusersettings = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Clair Obscur GameUserSettings.ini configuration";
    };
  };
  config = lib.mkIf cfg.enable {
    usr.files.".local/share/Steam/steamapps/compatdata/1903340/pfx/drive_c/users/steamuser/AppData/Local/Sandfall/Saved/Config/Windows/GameUserSettings.ini" = {
      clobber = true;
      generator = lib.generators.toINI {};
      value = {
        "ScalabilityGroups" = {
          "sg.ResolutionQuality" = "75";
          "sg.ViewDistanceQuality" = "0";
          "sg.AntiAliasingQuality" = "0";
          "sg.ShadowQuality" = "0";
          "sg.GlobalIlluminationQuality" = "0";
          "sg.ReflectionQuality" = "0";
          "sg.PostProcessQuality" = "0";
          "sg.TextureQuality" = "0";
          "sg.EffectsQuality" = "0";
          "sg.FoliageQuality" = "0";
          "sg.ShadingQuality" = "0";
          "sg.LandscapeQuality" = "0";
        };
        "/Script/SandFall.ConfigurableGameUserSettings" = {
          SettingsData = "(bEnableSubtitles=True,SubtitlesSize=0,bEnableSubtitlesSpeakerDisplay=True,bEnableSubtitlesSpeakerPersonalColor=False,bEnableTutorials=True,bEnableCustomizationDuringCinematics=True,bEnableAutoSkipLinesDuringDialogues=False,bEnableControllerForceFeedback=True,bInvertCameraPitch=False,bInvertCameraYaw=False,CameraYawInputMultiplier=1.000000,CameraPitchInputMultiplier=1.000000,CameraInputMultiplier=1.000000,bEnableHoldInputToSprint=True,bEnableHoldInputToAim=True,MasterVolume=0.400000,MusicVolume=1.000000,MusicVolume_Combat=1.000000,MusicVolume_Exploration=1.000000,VoiceVolume=1.000000,VoiceVolume_Combat=1.000000,VoiceVolume_Exploration=1.000000,UserInterfaceVolume=1.000000,SpecialEffectsVolume=1.000000,SpecialEffectsVolume_Combat=1.000000,SpecialEffectsVolume_Exploration=1.000000,NotFocusedVolume=0.000000,bEnableMotionBlur=True,bEnableFilmGrain=True,bEnableChromaticAberration=True,bEnableVignette=True,GammaValue=1.000000,ContrastValue=1.000000,BrightnessValue=1.000000,bEnableCameraShakes=True,bCameraMovement=True,bPersistentCenterDot=False,bEnableAutomaticBattleQTE=False,ColorVisionDeficiency=NormalVision,ColorVisionDeficiencyCorrectionSeverity=1.000000,ApplicationScale=1.000000,MenuUltrawideConstrain=(X=0,Y=0),BattleUltrawideConstrain=(X=0,Y=0),ConsoleGraphicPreset=0)";
          CurrentSelectedMonitorIDName = ''"MONITOR\\Default_Monitor\\{4D36E96E-E325-11CE-BFC1-08002BE10318}\\0000Default_Monitor"'';
          CurrentSelectedUpscaler = "DLSS";
          CurrentSelectedUpscalerQualityMode = "2";
          UserConfigHardwareProfile = "AMDRyzen97950X16-CoreProcessor1088283498604318";
          CurrentSelectedFrameGenerationMode = "0";
          CurrentSelectedLowLatencyMode = "1";
          bUseVSync = "False";
          bUseDynamicResolution = "False";
          ResolutionSizeX = "2560";
          ResolutionSizeY = "1440";
          LastUserConfirmedResolutionSizeX = "2560";
          LastUserConfirmedResolutionSizeY = "1440";
          WindowPosX = "0";
          WindowPosY = "0";
          FullscreenMode = "2";
          LastConfirmedFullscreenMode = "2";
          PreferredFullscreenMode = "2";
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
          LastCPUBenchmarkResult = "490.910095";
          LastGPUBenchmarkResult = "1231.906250";
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
