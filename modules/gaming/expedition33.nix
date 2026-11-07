{
  unreal,
  config,
  lib,
  pkgs,
  ...
}: let
  iniDir = "${config.user.paths.steam}/steamapps/compatdata/1903340/pfx/drive_c/users/steamuser/AppData/Local/Sandfall/Saved/Config/Windows";
  win64 = "${config.user.paths.steam}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64";
  version = "0.0.13";
  clairObscurFix = pkgs.fetchzip {
    url = "https://codeberg.org/Lyall/ClairObscurFix/releases/download/${version}/ClairObscurFix_${version}.zip";
    sha256 = "160xv8gb95rn2kpcwv65j3q8fsi1wiayqchgn4gnkrh6g909qzrb";
    stripRoot = false;
  };
in {
  user.files = {
    "${win64}/ClairObscurFix.asi".source = "${clairObscurFix}/ClairObscurFix.asi";

    "${win64}/dsound.dll".source = "${clairObscurFix}/dsound.dll";

    "${win64}/ClairObscurFix.ini" = {
      generator = lib.generators.toINI {};
      value = {
        "Developer Console".Enabled = true;
        "Skip Intro Logos".Enabled = true;
        "Uncap Cutscene FPS" = {
          Enabled = true;
          AllowFrameGen = false;
        };
        "Adjust Resolution Checks".Enabled = true;
        "Maximum Timer Resolution".Enabled = true;
        "Cutscenes" = {
          DisableLetterboxing = true;
          DisablePillarboxing = true;
        };
        "Fix Movies".Enabled = true;
        "Disable Subtitle Blur".Enabled = false;
        "Sharpening".Strength = "0";
      };
    };

    "${iniDir}/Engine.ini" = {
      generator = lib.generators.toINI {};
      value = lib.recursiveUpdate unreal."Engine.ini" {
        "ConsoleVariables" = {
          "r.DiffuseIndirect.Denoiser" = "2";
          "r.FastBlurThreshold" = "0";
          "r.ForceHighestMipOnUITextures" = "1";
          "r.Lumen.Reflections.MaxRoughnessToTraceForFoliage" = "0";
          "r.Lumen.Reflections.Temporal.DistanceThreshold" = "0.003";
          "r.Lumen.ScreenProbeGather.IrradianceFormat" = "1";
          "r.Lumen.ScreenProbeGather.RadianceCache.NumProbesToTraceBudget" = "100";
          "r.Lumen.ScreenProbeGather.ScreenTraces.HZBTraversal.FullResDepth" = "0";
          "r.Lumen.ScreenProbeGather.StochasticInterpolation" = "1";
          "r.Lumen.ScreenProbeGather.Temporal.DistanceThreshold" = "0.03";
          "r.Lumen.ScreenProbeGather.Temporal.MaxFramesAccumulated" = "24";
          "r.Lumen.ScreenProbeGather.TemporalFilterProbes" = "1";
          "r.Lumen.ScreenProbeGather.TwoSidedFoliageBackfaceDiffuse" = "0";
          "r.Lumen.TranslucencyVolume.GridPixelSize" = "128";
          "r.Lumen.TranslucencyVolume.RadianceCache.ProbeAtlasResolutionInProbes" = "96";
          "r.Lumen.TranslucencyVolume.RadianceCache.ProbeResolution" = "8";
          "r.Lumen.TranslucencyVolume.TraceFromVolume" = "0";
          "r.LumenScene.FarField.MaxTraceDistance" = "499997";
          "r.LumenScene.GlobalSDF.Resolution" = "128";
          "r.LumenScene.Radiosity.HemisphereProbeResolution" = "1";
          "r.LumenScene.Radiosity.ProbeSpacing" = "8";
          "r.LumenScene.SurfaceCache.MeshCardsMergeInstances" = "1";
          "r.MaterialQualityLevel" = "0";
          "r.MinRoughnessOverride" = "0.4";
          "r.Shadow.Virtual.SMRT.TexelDitherScaleLocal" = "10";
          "r.Tonemapper.Sharpen" = "0.1";
          "r.VolumetricCloud" = "0";
          "r.VT.MaxUploadsPerFrame" = "64";
          "r.VT.MaxTilesProducedPerFrame" = "64";

          "r.Lumen.Reflections.MaxRayIntensity" = "4";
          "r.Lumen.Reflections.ScreenSpaceReconstruction.KernelRadius" = "24";
          "r.Lumen.ScreenProbeGather.DownsampleFactor" = "32";
          "r.Lumen.ScreenProbeGather.GatherOctahedronResolutionScale" = "1";
          "r.Lumen.ScreenProbeGather.RadianceCache.ProbeResolution" = "8";
          "r.Lumen.ScreenProbeGather.ShortRangeAO" = "1";
          "r.Lumen.TraceMeshSDFs.Allow" = "0";
          "r.LumenScene.SurfaceCache.AtlasSize" = "3400";
          "r.MaxAnisotropy" = "16";
          "r.Nanite.MaxPixelsPerEdge" = "2";
          "r.RefractionQuality" = "1";
          "r.Shadow.RadiusThreshold" = "0.06";
          "r.Shadow.Virtual.Clipmap.WPODisableDistance.LodBias" = "-5";
          "r.Shadow.Virtual.ResolutionLodBiasDirectional" = "-0.3";
          "r.Shadow.Virtual.ResolutionLodBiasDirectionalMoving" = "1.5";
          "r.Shadow.Virtual.ResolutionLodBiasLocal" = "1";
          "r.Shadow.Virtual.ResolutionLodBiasLocalMoving" = "2.5";
          "r.Shadow.Virtual.SMRT.RayCountDirectional" = "4";
          "r.Shadow.Virtual.SMRT.RayCountLocal" = "5";
          "r.Shadow.Virtual.SMRT.SamplesPerRayDirectional" = "2";
          "r.Shadow.Virtual.SMRT.TexelDitherScaleDirectional" = "4";
          "r.SkeletalMeshLODBias" = "2";
          "r.SSR.Quality" = "1";
          "r.VolumetricFog.GridSizeZ" = "64";
          "r.VolumetricFog.HistoryWeight" = "0.95";
          "r.VolumetricFog.VoxelizationShowOnlyPassIndex" = "-1";

          "r.EyeAdaptation.BlackHistogramBucketInfluence" = "1";
          "r.EyeAdaptation.LensAttenuation" = "0.5";
          "r.SkylightIntensityMultiplier" = "2";
          "r.Lumen.Reflections.SpecularScale" = "1.5";

          "r.LumenScene.Radiosity.UpdateFactor" = "128";
          "r.LumenScene.DirectLighting.UpdateFactor" = "128";
          "r.Lumen.Reflections.DownsampleFactor" = "1";
          "r.Lumen.Reflections.Temporal.MaxFramesAccumulated" = "32";

          "r.DepthOfFieldQuality" = "0";
          "r.FilmGrain" = "0";
          "r.LensFlareQuality" = "0";
          "r.NT.Lens.ChromaticAberration.Intensity" = "0";
          "r.SceneColorFringeQuality" = "0";
          "r.Tonemapper.Quality" = "0";

          "r.DefaultFeature.AntiAliasing" = "0";
          "r.PostProcessAAQuality" = "0";
          "r.TemporalAA.Algorithm" = "0";
          "r.TemporalAA.Upsampling" = "0";
          "r.TSR.History.ScreenPercentage" = "0";
          "r.NGX.DLSS.PreferNISSharpen" = "0";
          "r.NGX.LogLevel" = "0";

          "r.ViewDistanceScale" = "1.5";

          "r.RayTracing" = "0";
          "r.RayTracing.GlobalIllumination" = "0";
          "r.RayTracing.Reflections" = "0";
          "r.RayTracing.Shadows" = "0";

          "fx.Niagara.RayTracing.Enable" = "0";
          "r.Niagara.RayTracing.Enable" = "0";

          "bAllowThreadedRendering" = "1";
          "MaxShaderJobBatchSize" = "0";
          "MaxShaderJobs" = "0";
          "NumUnusedShaderCompilingThreads" = "0";

          "r.UseAsyncShaderPrecompilation" = "1";

          "r.FinishCurrentFrame" = "0";
        };
      };
    };

    "${iniDir}/GameUserSettings.ini" = {
      generator = lib.generators.toINI {};
      value = lib.recursiveUpdate unreal."GameUserSettings.ini" {
        "ScalabilityGroups" = {
          "sg.ResolutionQuality" = "70";
          "sg.ViewDistanceQuality" = "2";
          "sg.AntiAliasingQuality" = "2";
          "sg.ShadowQuality" = "2";
          "sg.GlobalIlluminationQuality" = "2";
          "sg.ReflectionQuality" = "2";
          "sg.PostProcessQuality" = "2";
          "sg.TextureQuality" = "2";
          "sg.EffectsQuality" = "2";
          "sg.FoliageQuality" = "2";
          "sg.ShadingQuality" = "2";
          "sg.LandscapeQuality" = "2";
        };
        "/Script/SandFall.ConfigurableGameUserSettings" = {
          SettingsData = "(bEnableSubtitles=True,SubtitlesSize=0,bEnableSubtitlesSpeakerDisplay=True,bEnableSubtitlesSpeakerPersonalColor=True,bEnableTutorials=True,bEnableCustomizationDuringCinematics=True,bEnableAutoSkipLinesDuringDialogues=False,bEnableControllerForceFeedback=True,bInvertCameraPitch=False,bInvertCameraYaw=False,CameraYawInputMultiplier=1.000000,CameraPitchInputMultiplier=1.000000,CameraInputMultiplier=1.900000,bEnableHoldInputToSprint=True,bEnableHoldInputToAim=True,MasterVolume=0.400000,MusicVolume=1.000000,MusicVolume_Combat=1.000000,MusicVolume_Exploration=1.000000,VoiceVolume=1.000000,VoiceVolume_Combat=1.000000,VoiceVolume_Exploration=1.000000,UserInterfaceVolume=1.000000,SpecialEffectsVolume=1.000000,SpecialEffectsVolume_Combat=1.000000,SpecialEffectsVolume_Exploration=1.000000,NotFocusedVolume=0.400000,bEnableMotionBlur=False,bEnableFilmGrain=False,bEnableChromaticAberration=False,bEnableVignette=False,GammaValue=1.000000,ContrastValue=1.000000,BrightnessValue=1.000000,bEnableCameraShakes=True,bCameraMovement=True,bPersistentCenterDot=False,bEnableAutomaticBattleQTE=False,ColorVisionDeficiency=NormalVision,ColorVisionDeficiencyCorrectionSeverity=1.000000,ApplicationScale=1.000000,MenuUltrawideConstrain=(X=16,Y=9),BattleUltrawideConstrain=(X=16,Y=9),ConsoleGraphicPreset=0)";
          CurrentSelectedMonitorIDName = "MONITOR\\Default_Monitor\\{4D36E96E-E325-11CE-BFC1-08002BE10318}\\0000Default_Monitor";
          CurrentSelectedUpscaler = "DLSS";
          CurrentSelectedUpscalerQualityMode = "4";
          UserConfigHardwareProfile = "";
          CurrentSelectedFrameGenerationMode = "0";
          CurrentSelectedLowLatencyMode = "1";
          bUseVSync = "False";
          bUseDynamicResolution = "False";
          ResolutionSizeX = "2543";
          ResolutionSizeY = "1418";
          WindowPosX = "0";
          WindowPosY = "0";
          FullscreenMode = "2";
          LastConfirmedFullscreenMode = "2";
          PreferredFullscreenMode = "1";
          Version = "5";
          AudioQualityLevel = "0";
          LastConfirmedAudioQualityLevel = "0";
          FrameRateLimit = "0.000000";
          DesiredScreenWidth = "2543";
          DesiredScreenHeight = "1418";
          bUseHDRDisplayOutput = "False";
          HDRDisplayOutputNits = "1000";
        };
      };
    };

    "${iniDir}/Scalability.ini" = {
      generator = lib.generators.toINI {};
      value = unreal."Scalability.ini";
    };
  };
}
