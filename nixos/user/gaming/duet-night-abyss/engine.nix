{
  config,
  lib,
  ...
}: {
  options.user.gaming.duet-night-abyss = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Duet Night Abyss configuration";
    };
  };
  config = lib.mkIf config.user.gaming.duet-night-abyss.enable {
    usr.files.".local/share/Steam/steamapps/compatdata/3286820662/pfx/drive_c/users/steamuser/AppData/Local/Duet/Saved/Config/Windows/Engine.ini" = {
      clobber = true;
      generator = lib.generators.toINI {};
      value = {
        "Core.System" = {
          Paths = [
            "../../../Engine/Content"
            "%GAMEDIR%Content"
            "../../../EM/Plugins/DynamicAtlas/Content"
          ];
        };
        "WindowsApplication.Accessibility" = {
          StickyKeysHotkey = "False";
          ToggleKeysHotkey = "False";
          FilterKeysHotkey = "False";
          StickyKeysConfirmation = "False";
          ToggleKeysConfirmation = "False";
          FilterKeysConfirmation = "False";
        };
        "ConsoleVariables" = {
          bEnableMouseSmoothing = "0";
          bViewAccelerationEnabled = "0";
          RawMouseInputEnabled = "1";
          bOptimizeAnimBlueprintMemberVariableAccess = "1";
          bAllowMultiThreadedAnimationUpdate = "1";
          bAllowMultiThreadedShaderCompile = "1";
          bEnableMultiCoreRendering = "1";
          AttemptStuckThreadResuscitation = "True";
          D3D12.MaxCommandsPerCommandList = "100000";
          D3D12.AdjustTexturePoolSizeBasedOnBudget = "1";
          D3D11.MaxCommandsPerCommandList = "100000";
          D3D11.AdjustTexturePoolSizeBasedOnBudget = "1";
          PakCache.CachePerPakFile = "1";
          PakCache.UseNewTrim = "1";
          "foliage.MaxOcclusionQueriesPerComponent" = "1000";
          "foliage.MinOcclusionQueriesPerComponent" = "900";
          "foliage.ditheredLOD" = "1";
          "foliage.MinInstancesPerOcclusionQuery" = "70000";
          "foliage.MinimumScreenSize" = "0.00000001";
          "grass.DisableDynamicShadows" = "0";
          "r.HZBOcclusion" = "1";
          "au.DisableBinauralSpatialization" = "1";
          "au.DisableParallelSourceProcessing" = "1";
          "r.Streaming.UsePerTextureBias" = "1";
          "r.Streaming.DefragDynamicBounds" = "1";
          "r.GPUDefrag.MaxRelocations" = "4";
          "r.PreTileTextures" = "1";
          "au.BakedAnalysisEnabled" = "0";
          bDisableAILogging = "1";
          LogTelemetry = "off";
          LogAnalytics = "off";
        };
        "/Script/Engine.RendererSettings" = {
          "r.DefaultFeature.Antialiasing" = "1";
          "r.TemporalAACurrentFrameWeight" = "0.05";
          "r.TemporalAAFilterSize" = "1.0";
          "r.TemporalAA.Algorithm" = "1";
          "r.TemporalAA.Upsampling" = "1";
          "r.TemporalAASharpness" = "0";
          "r.TemporalAASamples" = "4";
          "r.PostProcessAAQuality" = "6";
          "r.Reflections.Denoiser" = "2";
          "r.Reflections.Denoiser.TemporalAccumulation" = "1";
          "r.Cache.UpdateEveryFrame" = "1";
          "r.Cache.DrawInterpolationPoints" = "1";
          "r.MultithreadedRendering" = "1";
          "r.AllowMultiThreadedShaderCreation" = "1";
          "r.EnableMultiThreadedRendering" = "1";
          "r.ThreadedShaderCompilation" = "1";
          "r.TextureStreaming.DiscardUnusedMips" = "1";
          "r.ThreadPool.EnableBackgroundThreads" = "1";
          "r.ThreadPool.EnableHighPriorityThreads" = "1";
          "r.AlsoUseSphereForFrustumCull" = "1";
          "r.OptimizedWPO" = "1";
          "r.Shaders.Optimize" = "1";
          "r.Streaming.Threaded" = "1";
          "r.Shadow.CSMCaching" = "1";
          "r.ShaderCompiler.AllowDistributedCompilation" = "0";
          "FX.MaxGPUParticlesSpawnedPerFrame" = "5000";
          "FX.SkipVectorVMBackendOptimizations" = "1";
          "FX.MaxCPUParticlesPerEmitter" = "3000";
          "FX.EnableCircularAnimTrailDump" = "0";
          "FX.ParticlePerfStats.Enabled" = "0";
          "FX.Niagara.DebugDraw.Enabled" = "0";
          "r.CreateShadersOnLoad" = "1";
          "niagara.CreateShadersOnLoad" = "1";
          "r.Vignette" = "0";
          "r.BlurGBuffer" = "0";
          "r.DisableDistortion" = "1";
          "r.Distortion" = "0";
          "r.DepthOfField" = "0";
          "r.DepthOfField.MaxSize" = "0";
          "r.DOF.TemporalAAQuality" = "0";
          "r.DOF.Scatter.NeighborCompareMaxColor" = "0";
          "r.DOF.Kernel.MaxBackgroundRadius" = "0.0001";
          "r.DOF.Kernel.MaxForegroundRadius" = "0.0001";
          "r.DOF.Recombine.EnableBokehSettings" = "0";
          "r.DOF.Recombine.Quality" = "0";
          "r.DOF.Gather.RingCount" = "0";
          "r.DepthOfField.FarBlur" = "0";
          "r.SceneColorFringeQuality" = "0";
          "r.SceneColorFringe.Max" = "0";
          "sdk.DisableCutsceneCA" = "1";
          "r.MeshParticle.MinDetailModeForMotionBlur" = "0";
          "r.MotionBlurIntensityOverride" = "0.000000";
          "r.MotionBlurLimitationOverride" = "0.000000";
          "r.MotionBlurRestrainOverride" = "0.000000";
          "r.MotionBlurScatter" = "0";
          "r.Tonemapper.Sharpen" = "0.75";
          "r.Tonemapper.Quality" = "0";
          "r.Tonemapper.GrainQuantization" = "0";
          "r.DefaultFeature.LensFlare" = "0";
          "r.DefaultFeature.MotionBlur" = "0";
          "r.DefaultFeature.DOF" = "0";
          "r.MotionBlurQuality" = "0";
          "r.Shadow.ContactShadow" = "1";
          "r.Shadow.DistanceField" = "1";
          "r.DistanceFieldLighting" = "1";
          "r.DistanceFieldShadowing" = "1";
          "r.DistanceFieldGI" = "1";
          "r.DistanceFieldAO" = "1";
          "r.UseShaderCaching" = "1";
          "r.UseShaderPredraw" = "1";
          "r.SSR.HalfResSceneColor" = "0";
          "r.CapsuleShadows" = "1";
          "r.SSGI.Enable" = "1";
          "r.SSGI.HalfRes" = "1";
          "r.SSGI.Quality" = "2";
          "r.AmbientOcclusion.Method" = "1";
          "r.GTAO.Combined" = "1";
          "r.GTAO.ThicknessBlend" = "0";
          "r.GTAO.Downsample" = "1";
          "r.GTAO.FalloffEnd" = "500";
          "r.GTAO.FalloffStartRatio" = "0";
          "r.Shadow.FadeExponent" = "0";
          "r.Shadow.FadeResolution" = "0";
          "r.Fog" = "1";
          "r.ParticleQuality" = "3";
          "r.MaxAnisotropy" = "16";
          "r.AmbientOcclusionRadiusScale" = "2";
          "r.BloomCustom.ClampMaxlight" = "0.05";
        };
        "SystemSettings" = {
          "r.ParallelGraphics" = "1";
          "r.ParallelRendering" = "1";
          "r.ParallelParticleUpdate" = "1";
          "r.ParallelPhysicsScene" = "1";
          "r.ParallelDistanceField" = "0";
          "r.ParallelShaderCompile" = "0";
          "r.ParallelPostProcessing" = "0";
          "r.ParallelSkeletalClothSimulate" = "1";
          "r.ParallelSkeletalClothUpdateVerts" = "1";
          "r.ParallelDistributedScene" = "0";
          "r.ParallelMeshBuildUseJobCulling" = "1";
          "r.ParallelMeshBuildUseJobMerging" = "1";
          "r.ParallelMeshDrawCommands" = "1";
          "r.ParallelMeshMerge" = "1";
          "r.ParallelMeshProcessing" = "1";
          "r.ParallelLandscapeLayerUpdate" = "1";
          "r.ParallelLandscapeSplineUpdate" = "1";
          "r.FastVRam.GBufferVelocity" = "1";
          "r.FastVRam.ShadowPerObject" = "1";
          "r.FastVRam.ShadowPointLight" = "1";
          "r.FastVRam.SSR" = "1";
          "r.FastVRam.CustomDepth" = "1";
          "r.FastVRam.GBufferA" = "1";
          "r.FastVRam.GBufferB" = "1";
          "r.FastVRam.GBufferC" = "1";
          "r.FastVRam.GBufferD" = "1";
          "r.FastVRam.GBufferE" = "1";
          "r.FastVRam.GBufferF" = "1";
          "r.ShaderPipelineCache.PreOptimizeEnabled" = "1";
          "r.ShaderPipelineCache.LazyLoadShadersWhenPSOCacheIsPresent" = "1";
          "r.ShaderPipelineCache.SaveAfterPSOsLogged" = "5";
          "r.ShaderPipelineCache.BackgroundBatchSize" = "8";
          "r.ShaderPipelineCache.BackgroundBatchTime" = "1.0";
          "r.ShaderLibrary.PrintExtendedStats" = "0";
          "r.FrustumCullNumWordsPerTask" = "512";
          "r.HighQualityLightShafts" = "1";
          "r.LightShaftDownSampleFactor" = "4";
          "r.Streaming.LimitPoolSizeToVRAM" = "1";
          "r.Streaming.AmortizeCPUToGPUCopy" = "1";
          "r.Streaming.NumStaticComponentsProcessedPerFrame" = "1000";
          "r.Streaming.MaxNumTexturesToStreamPerFrame" = "1000";
          "r.Streaming.AllowFastForceResident" = "0";
          "r.Shadow.UnbuiltPreviewInGame" = "0";
          "r.Shadow.CacheWholeSceneShadows" = "0";
          "r.Shadow.CacheNonWholeSceneShadows" = "1";
          "r.Shadow.FadeExponent" = "0.001";
          "r.VolumetricFog.GridPixelSize" = "32";
          "r.VolumetricFog.GridSizeZ" = "192";
        };
        "ScalabilityGroups" = {
          "sg.FoliageQuality" = "3";
          "sg.CharacterTextureDetailQuality" = "3";
          "sg.ClothQuality" = "3";
          "sg.TessellationQuality" = "3";
          "sg.ScreenSpaceShadowQuality" = "2";
          "sg.TiledResourcesQuality" = "3";
          "sg.TranslucencyQuality" = "2";
          "sg.LandscapeQuality" = "3";
          "sg.CapsuleShadowQuality" = "3";
        };
        "CrashReportClient" = {
          bAgreeToCrashUpload = "0";
          bImplicitSend = "0";
        };
      };
    };
  };
}
