{
  config,
  lib,
  pkgs,
  ...
}: let
  steamPath = lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam;
  iniDir = "${steamPath}/steamapps/compatdata/1903340/pfx/drive_c/users/steamuser/AppData/Local/Sandfall/Saved/Config/Windows";
  version = "0.0.13";
  clairObscurFix = pkgs.fetchzip {
    url = "https://codeberg.org/Lyall/ClairObscurFix/releases/download/${version}/ClairObscurFix_${version}.zip";
    sha256 = "160xv8gb95rn2kpcwv65j3q8fsi1wiayqchgn4gnkrh6g909qzrb";
    stripRoot = false;
  };
in {
  manzil.users."${config.user.name}".files = {
    "${steamPath}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/ClairObscurFix.asi" = {
      source = "${clairObscurFix}/ClairObscurFix.asi";
    };

    "${steamPath}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/dsound.dll" = {
      source = "${clairObscurFix}/dsound.dll";
    };

    "${steamPath}/steamapps/common/Expedition 33/Sandfall/Binaries/Win64/ClairObscurFix.ini" = {
      generator = lib.generators.toINI {};
      value = {
        "Developer Console" = {
          Enabled = true;
        };
        "Skip Intro Logos" = {
          Enabled = true;
        };
        "Uncap Cutscene FPS" = {
          Enabled = true;
          AllowFrameGen = false;
        };
        "Adjust Resolution Checks" = {
          Enabled = true;
        };
        "Maximum Timer Resolution" = {
          Enabled = true;
        };
        "Cutscenes" = {
          DisableLetterboxing = true;
          DisablePillarboxing = true;
        };
        "Fix Movies" = {
          Enabled = true;
        };
        "Disable Subtitle Blur" = {
          Enabled = false;
        };
        "Sharpening" = {
          Strength = "0";
        };
      };
    };

    "${iniDir}/Engine.ini" = {
      generator = lib.generators.toINI {};
      value = {
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

          "bAllowAsynchronousShaderCompiling" = "1";
          "bAllowCompilingThroughWorkerThreads" = "1";
          "bAllowMultiThreadedShaderCompile" = "1";
          "bAllowShaderCompilingWorker" = "1";
          "bAllowThreadedRendering" = "1";
          "bAsyncShaderCompileWorkerThreads" = "1";
          "bEnableOptimizedShaderCompilation" = "1";
          "bOptimizeForLocalShaderBuilds" = "1";
          "bUseBackgroundCompiling" = "1";
          "MaxShaderJobBatchSize" = "0";
          "MaxShaderJobs" = "0";
          "NumUnusedShaderCompilingThreads" = "0";
          "UseAllCores" = "1";
          "TaskGraph.Enable" = "1";
          "TaskGraph.NumForegroundWorkers" = "-1";
          "TaskGraph.NumWorkerThreads" = "-1";
          "r.ForceAllCoresForShaderCompiling" = "1";
          "r.ThreadedShaderCompilation" = "1";

          "r.AllowMultiThreadedShaderCreation" = "1";
          "r.EnableMultiThreadedRendering" = "1";
          "r.RHICmdUseParallelAlgorithms" = "1";
          "r.RHICmdUseThread" = "1";
          "r.RHIThread" = "1";
          "r.RHIThread.Priority" = "2";
          "r.RHI.UseParallelDispatch" = "1";
          "r.RenderThread.Priority" = "2";
          "r.RenderThread.EnableTaskGraphThread" = "1";
          "r.AsyncCompute" = "1";
          "r.AsyncCompute.ParallelDispatch" = "1";
          "r.AsyncPipelineCompile" = "1";
          "r.UseAsyncShaderPrecompilation" = "1";

          "r.ParallelShaderCompile" = "1";
          "r.ParallelRendering" = "1";
          "r.ParallelBasePass" = "1";
          "r.ParallelGraphics" = "1";
          "r.ParallelInitViews" = "1";
          "r.ParallelCulling" = "1";
          "r.ParallelDestruction" = "1";

          "gc.AllowParallelGC" = "1";
          "gc.CreateGCClusters" = "1";
          "gc.MultithreadedDestructionEnabled" = "1";

          "p.AsyncSceneEnabled" = "1";
          "p.Chaos.PerParticleCollision.ISPC" = "1";
          "p.Chaos.Spherical.ISPC" = "1";
          "p.Chaos.Spring.ISPC" = "1";
          "p.Chaos.TriangleMesh.ISPC" = "1";
          "p.Chaos.VelocityField.ISPC" = "1";

          "bDisableMouseAcceleration" = "1";
          "bEnableMouseSmoothing" = "0";
          "bViewAccelerationEnabled" = "0";
          "RawMouseInputEnabled" = "1";

          "t.MaxFPS" = "0";
          "bSmoothFrameRate" = "0";
          "r.OneFrameThreadLag" = "1";
          "r.FinishCurrentFrame" = "0";
        };
      };
    };

    "${iniDir}/GameUserSettings.ini" = {
      generator = lib.generators.toINI {};
      value = {
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
        "/Script/Engine.GameUserSettings" = {
          bUseDesiredScreenHeight = "False";
        };
      };
    };

    "${iniDir}/Scalability.ini" = {
      generator = lib.generators.toINI {};
      value = {
        "EffectsQuality@0" = {
          "r.SSS.Quality" = "0";
          "r.SSR.Quality" = "0";
          "r.ReflectionQuality" = "0";
          "r.LightShaftQuality" = "0";
          "FX.Niagara.QualityLevel" = "0";
        };
        "FoliageQuality@0" = {
          "foliage.DensityScale" = "0.1";
          "Grass.DensityScale" = "0.1";
          "Tree.DensityScale" = "0.1";
          "foliage.LODDistanceScale" = "0.1";
        };
        "ShadowQuality@0" = {
          "r.ShadowQuality" = "2";
          "r.Shadow.PerObject" = "1";
          "r.Shadow.ContactShadow" = "0";
          "r.Shadow.MaxCascades" = "3";
          "r.Shadow.MaxResolution" = "512";
          "r.Shadow.PerObjectShadowMapResolution" = "256";
        };
        "TextureQuality@0" = {
          "r.MaxAnisotropy" = "4";
          "r.VT.MaxAnisotropy" = "4";
          "r.Streaming.Boost" = "0.5";
        };
        "ViewDistanceQuality@0" = {
          "r.ViewDistanceScale" = "0.5";
          "r.foliageDistanceScale" = "0.5";
          "r.LightMaxDrawDistanceScale" = "0.5";
          "r.StaticMeshLODDistanceScale" = "1.0";
          "r.AOMaxViewDistance" = "5000";
        };

        "EffectsQuality@1" = {
          "r.SSS.Quality" = "1";
          "r.SSR.Quality" = "1";
          "r.ReflectionQuality" = "1";
          "r.LightShaftQuality" = "1";
          "FX.Niagara.QualityLevel" = "1";
        };
        "FoliageQuality@1" = {
          "foliage.DensityScale" = "0.4";
          "Grass.DensityScale" = "0.4";
          "Tree.DensityScale" = "0.4";
          "foliage.LODDistanceScale" = "0.4";
        };
        "ShadowQuality@1" = {
          "r.ShadowQuality" = "3";
          "r.Shadow.PerObject" = "2";
          "r.Shadow.ContactShadow" = "0";
          "r.Shadow.MaxCascades" = "4";
          "r.Shadow.MaxResolution" = "1024";
          "r.Shadow.PerObjectShadowMapResolution" = "512";
        };
        "TextureQuality@1" = {
          "r.MaxAnisotropy" = "8";
          "r.VT.MaxAnisotropy" = "8";
          "r.Streaming.Boost" = "1.0";
        };
        "ViewDistanceQuality@1" = {
          "r.ViewDistanceScale" = "1.0";
          "r.foliageDistanceScale" = "1.0";
          "r.LightMaxDrawDistanceScale" = "1.0";
          "r.StaticMeshLODDistanceScale" = "1.0";
          "r.AOMaxViewDistance" = "10000";
        };

        "EffectsQuality@2" = {
          "r.SSS.Quality" = "2";
          "r.SSR.Quality" = "2";
          "r.ReflectionQuality" = "2";
          "r.LightShaftQuality" = "2";
          "FX.Niagara.QualityLevel" = "2";
        };
        "FoliageQuality@2" = {
          "foliage.DensityScale" = "1.0";
          "Grass.DensityScale" = "1.0";
          "Tree.DensityScale" = "1.0";
          "foliage.LODDistanceScale" = "1.0";
        };
        "ShadowQuality@2" = {
          "r.ShadowQuality" = "4";
          "r.Shadow.PerObject" = "4";
          "r.Shadow.ContactShadow" = "1";
          "r.Shadow.MaxCascades" = "6";
          "r.Shadow.MaxResolution" = "1024";
          "r.Shadow.PerObjectShadowMapResolution" = "1024";
        };
        "TextureQuality@2" = {
          "r.MaxAnisotropy" = "12";
          "r.VT.MaxAnisotropy" = "12";
          "r.Streaming.Boost" = "1.5";
        };
        "ViewDistanceQuality@2" = {
          "r.ViewDistanceScale" = "2.0";
          "r.foliageDistanceScale" = "2.0";
          "r.LightMaxDrawDistanceScale" = "2.0";
          "r.StaticMeshLODDistanceScale" = "1.2";
          "r.AOMaxViewDistance" = "20000";
        };

        "EffectsQuality@3" = {
          "r.SSS.Quality" = "3";
          "r.SSR.Quality" = "3";
          "r.SSR.MaxRoughness" = "1.0";
          "r.ReflectionQuality" = "3";
          "r.LightShaftQuality" = "3";
          "r.RefractionQuality" = "3";
          "FX.Niagara.QualityLevel" = "3";
          "r.ParticleLightQuality" = "3";
        };
        "FoliageQuality@3" = {
          "foliage.DensityScale" = "2.0";
          "Grass.DensityScale" = "2.0";
          "Tree.DensityScale" = "2.0";
          "foliage.LODDistanceScale" = "2.0";
        };
        "ShadowQuality@3" = {
          "r.ShadowQuality" = "4";
          "r.Shadow.PerObject" = "4";
          "r.Shadow.ContactShadow" = "1";
          "r.Shadow.MaxCascades" = "8";
          "r.Shadow.MaxResolution" = "1536";
          "r.Shadow.PerObjectShadowMapResolution" = "1536";
          "r.Shadow.DepthBias" = "0";
        };
        "TextureQuality@3" = {
          "r.MaxAnisotropy" = "16";
          "r.VT.MaxAnisotropy" = "16";
          "r.Streaming.Boost" = "2.0";
        };
        "ViewDistanceQuality@3" = {
          "r.ViewDistanceScale" = "4.0";
          "r.foliageDistanceScale" = "4.0";
          "r.LightMaxDrawDistanceScale" = "4.0";
          "r.StaticMeshLODDistanceScale" = "1.3";
          "r.AOMaxViewDistance" = "30000";
        };

        "EffectsQuality@Cine" = {
          "r.SSS.Quality" = "3";
          "r.SSR.Quality" = "3";
          "r.SSR.MaxRoughness" = "1.0";
          "r.ReflectionQuality" = "3";
          "r.LightShaftQuality" = "3";
          "r.RefractionQuality" = "3";
          "FX.Niagara.QualityLevel" = "3";
          "r.ParticleLightQuality" = "3";
        };
        "FoliageQuality@Cine" = {
          "foliage.DensityScale" = "8.0";
          "Grass.DensityScale" = "8.0";
          "Tree.DensityScale" = "8.0";
          "foliage.LODDistanceScale" = "8.0";
        };
        "ShadowQuality@Cine" = {
          "r.ShadowQuality" = "5";
          "r.Shadow.PerObject" = "6";
          "r.Shadow.ContactShadow" = "1";
          "r.Shadow.MaxCascades" = "10";
          "r.Shadow.MaxResolution" = "2048";
          "r.Shadow.PerObjectShadowMapResolution" = "2048";
          "r.Shadow.DepthBias" = "0";
        };
        "TextureQuality@Cine" = {
          "r.MaxAnisotropy" = "16";
          "r.VT.MaxAnisotropy" = "16";
          "r.Streaming.Boost" = "3.0";
        };
        "ViewDistanceQuality@Cine" = {
          "r.ViewDistanceScale" = "100.0";
          "r.foliageDistanceScale" = "100.0";
          "r.LightMaxDrawDistanceScale" = "100.0";
          "r.StaticMeshLODDistanceScale" = "1.5";
          "r.AOMaxViewDistance" = "50000";
        };
      };
    };
  };
}
