{
  config,
  lib,
  ...
}: let
  iniDir = "${config.user.paths.steam}/steamapps/compatdata/1808500/pfx/drive_c/users/steamuser/AppData/Local/PioneerGame/Saved/Config/WindowsClient";
in {
  manzil.users."${config.user.name}".files = {
    "${iniDir}/Engine.ini" = {
      generator = lib.generators.toINI {};
      value = {
        "/Script/Engine.RendererSettings" = {
          "r.DefaultFeature.AntiAliasing" = "0";
          "r.PostProcessAAQuality" = "0";
          "r.FilmGrain" = "0";
          "r.Tonemapper.GrainQuantization" = "0";
          "r.Tonemapper.Sharpen" = "0";
          "r.VignetteIntensity" = "0";
          "r.NT.Lens.ChromaticAberration.Intensity" = "0";
          "r.SceneColorFringe.Max" = "0";
          "r.SceneColorFringeQuality" = "0";
          "r.DefaultFeature.Bloom" = "0";
          "r.BloomQuality" = "0";
          "r.DefaultFeature.LensFlare" = "0";
          "r.LensFlareQuality" = "0";
          "r.DefaultFeature.MotionBlur" = "0";
          "r.MotionBlurQuality" = "0";
          "r.MotionBlurMax" = "0";
          "r.MotionBlurAmount" = "0";
          "r.DepthOfFieldQuality" = "0";
          "r.EyeAdaptationQuality" = "0";
          "r.DefaultFeature.AmbientOcclusion" = "1";
          "r.MaxAnisotropy" = "16";
          "r.CustomDepth" = "3";
          "r.BasePassForceOutputsVelocity" = "1";
          "r.HZB.BuildAsync" = "1";
          "r.Lumen.DiffuseIndirect.AsyncCompute" = "1";
          "r.Lumen.Reflections.Temporal" = "1";
          "r.Lumen.ScreenProbeGather.AsyncCompute" = "1";
          "r.Lumen.ScreenProbeGather.TemporalFilterProbes" = "1";
          "r.LumenScene.DirectLighting.OffscreenShadowing.TraceMeshSDFs" = "0";
          "r.LumenScene.GPUDrivenUpdate" = "1";
          "r.LumenScene.Lighting.AsyncCompute" = "1";
          "r.LumenScene.MeshCardsPerTask" = "448";
          "r.LumenScene.ParallelUpdate" = "1";
          "r.LumenScene.PrimitivesPerTask" = "448";
          "r.LumenScene.SurfaceCache.AtlasSize" = "2048";
          "r.LumenScene.SurfaceCache.CardCapturesPerFrame" = "150";
          "r.LumenScene.SurfaceCache.Feedback.MinPageHits" = "32.0";
          "r.LumenScene.SurfaceCache.Feedback.UniqueElements" = "2048";
          "r.LumenScene.SurfaceCache.NumFramesToKeepUnusedPages" = "128";
          "r.LumenScene.SurfaceCache.RemovesPerFrame" = "128";
          "r.Nanite.MaterialVisibility" = "1";
          "r.Nanite.MaterialVisibility.Async" = "1";
          "r.Nanite.Streaming.MaxPageInstallsPerFrame" = "32";
          "r.Nanite.LargePageRectThreshold" = "256";
          "r.Nanite.VSMMeshShaderRasterization" = "1";
          "r.Shadow.CacheWPOPrimitives" = "1";
          "r.Shadow.DetectVertexShaderLayerAtRuntime" = "1";
          "r.Shadow.FadeExponent" = "0.75";
          "r.Shadow.TemporalFilter" = "1";
          "r.Shadow.TemporalSampleCount" = "8";
          "r.Shadow.Virtual.Cache.AllocateViaLRU" = "1";
          "r.Shadow.Virtual.Cache.InvalidateUseHZB" = "1";
          "r.Shadow.Virtual.NonNanite.IncludeInCoarsePages" = "0";
          "r.Shadow.Virtual.UseHZB" = "1";
          "r.VT.ParallelFeedbackTasks" = "1";
          "r.VT.CsvStats" = "0";
          "r.IO.VirtualTextures" = "1";
          "r.VRS.ContrastAdaptiveShading" = "0";
          "r.VRS.Enable" = "1";
          "r.VRS.EnableImage" = "1";
          "r.VRS.MaterialAdaptiveShading" = "1";
          "r.VRS.MotionAdaptiveShading" = "1";
          "r.VRS.Tier" = "2";
          "r.Renderer.UseGPUInstancing" = "1";
          "r.SupportAllShaderPermutations" = "0";
          "r.PreTileTextures" = "1";
          "r.D3D.ForceDXC" = "1";
          "r.CompileShadersForDevelopment" = "0";
          "r.CookOutUnusedDetailModeComponents" = "1";
          "r.ShaderPipelineCache.Enabled" = "1";
          "r.ShaderPipelineCache.StartupCache" = "1";
          "r.ShaderPipelineCache.BatchSize" = "30";
          "r.ShaderPipelineCache.BatchTime" = "5";
          "r.ShaderPipelineCache.AsyncCompileRate" = "32";
          "r.ShaderPipelineCache.PrecompileBatchSize" = "30";
          "r.ShaderPipelineCache.PrecompileBatchTime" = "5";
          "r.ShaderPipelineCache.PrecompileFrameTime" = "20";
          "r.ShaderPipelineCache.PreOptimizeEnabled" = "1";
          "r.ShaderLibrary.PrintExtendedStats" = "0";
          "r.PipelineStateCache.AsyncCompileAfterTypes" = "1";
          "r.Shaders.Optimize" = "1";
          "r.Shaders.RemoveUnusedInterpolators" = "1";
          "r.UseAsyncShaderPrecompilation" = "1";
          "r.DistanceFields.ParallelUpdate" = "1";
          "r.InstanceCulling.OcclusionCull" = "1";
          "r.LODFadeTime" = "0.75";
          "r.RendererOverrideVirtualTextureScalabilityGroup" = "0";
          "r.SkyAtmosphere.AerialPerspectiveLUT.FastApplyOnOpaque" = "1";
          "r.TemporalAA.Upsampling" = "0";
        };

        "/Script/D3D12RHI.D3D12Options" = {
          "D3D12.AFRUseFramePacing" = "1";
          "D3D12.AllowPoolAllocateIndirectArgBuffers" = "1";
          "D3D12.AsyncDeferredDeletion" = "1";
          "D3D12.ForceThirtyHz" = "0";
          "D3D12.InsertOuterOcclusionQuery" = "1";
          "D3D12.MaxCommandsPerCommandList" = "20000";
          "D3D12.MaximumFrameLatency" = "3";
          "D3D12.MultithreadedCommandListBuilding" = "1";
          "D3D12.PSO.DiskCache" = "1";
          "D3D12.PSO.DriverOptimizedDiskCache" = "1";
          "D3D12.ResidencyManagement" = "1";
          "D3D12.VRAMBufferPoolDefrag" = "1";
          "D3D12.VRAMBufferPoolDefrag.MaxCopySizePerFrame" = "33554432";
          "D3D12.VRAMTexturePoolDefrag" = "1";
          "D3D12.VRAMTexturePoolDefrag.MaxCopySizePerFrame" = "33554432";
          "D3D12.ZeroBufferSizeInMB" = "16";
        };

        "/Script/Engine.StreamingSettings" = {
          "r.Streaming.AmortizeCPUToGPUCopy" = "1";
          "r.Streaming.BuildTextureStreamingDataOnLoad" = "1";
          "r.Streaming.DefragDynamicBounds" = "1";
          "r.Streaming.FramesForFullUpdate" = "2";
          "r.Streaming.FullyLoadUsedTextures" = "0";
          "r.Streaming.HLODStrategy" = "2";
          "r.Streaming.LimitPoolSizeToVRAM" = "1";
          "r.Streaming.MaxMipLevelReduction" = "0";
          "r.Streaming.MinMipForSplitRequest" = "0";
          "r.Streaming.ParallelRenderAssetsNumWorkgroups" = "4";
          "r.Streaming.PredictiveBoost" = "1";
          "r.Streaming.PredictiveBoostHintSize" = "512";
          "r.Streaming.StressTest.ExtraAsyncLatency" = "0";
          "r.Streaming.UseAsyncRequestsForDDC" = "1";
          "r.Streaming.UseBackgroundThreadPool" = "1";
          "r.Streaming.UseMaterialDataStreaming" = "1";
          "r.Streaming.UseNewMetrics" = "1";
          "r.Streaming.UsePerTextureBias" = "1";
          "r.TextureStreaming" = "1";
          "r.TextureStreaming.DiscardUnusedMips" = "1";
          "r.TextureStreaming.UseBackgroundThreadPool" = "1";
          "r.TextureStreaming.UseDeferredLock" = "1";
          "s.AdaptiveAddToWorld.Enabled" = "1";
          "s.AsyncLoadingThreadEnabled" = "1";
          "s.AsyncLoadingThreadPriority" = "2";
          "s.AsyncLoadingTimeLimit" = "3.0";
          "s.IoDispatcherBufferMemoryMB" = "64";
          "s.IoDispatcherCacheSizeMB" = "2048";
          "s.IoDispatcherDecompressionWorkerCount" = "4";
          "s.MaxIncomingRequestsToStall" = "1";
          "s.MaxLevelRequestsAtOnceWhileInMatch" = "4";
          "s.MaxPrecacheRequestsInFlight" = "8";
          "s.MaxReadyRequestsToStallMB" = "0";
          "s.MinBulkDataSizeForAsyncLoading" = "0";
          "s.PriorityAsyncLoadingExtraTime" = "0.0";
          "s.PriorityLevelStreamingActorsUpdateExtraTime" = "0.0";
          "s.ProcessPrestreamingRequests" = "1";
          "r.IO.UseDirectStorage" = "1";
        };

        "TextureStreaming" = {
          "PoolSizeVRAMPercentage" = "70";
        };

        "ConsoleVariables" = {
          "a.ForceParallelAnimUpdate" = "1";
          "ai.DestroyNavDataInCleanUpAndMarkPendingKill" = "0";
          "AllowAsyncRenderThreadUpdatesDuringGamethreadUpdates" = "0";
          "Async.ParallelFor.YieldingTimeout" = "99";
          "AttemptStuckThreadResuscitation" = "1";
          "AudioThread.BatchAsyncBatchSize" = "256";
          "AudioThread.EnableBatchProcessing" = "1";
          "au.BakedAnalysisEnabled" = "0";
          "au.DisableParallelSourceProcessing" = "0";
          "au.voip.AlwaysPlayVoiceComponent" = "0";
          "bAllowAsynchronousShaderCompiling" = "1";
          "bAllowCompilingThroughWorkerThreads" = "1";
          "bAllowMultiThreadedAnimationUpdate" = "1";
          "bAllowMultiThreadedShaderCompile" = "1";
          "bAllowShaderCompilingWorker" = "1";
          "bAsyncShaderCompileWorkerThreads" = "1";
          "bCanBlueprintsTickByDefault" = "0";
          "bDisableMouseAcceleration" = "1";
          "bEnableMouseSmoothing" = "0";
          "bEnableMultiCoreRendering" = "1";
          "bEnableOptimizedShaderCompilation" = "1";
          "bOptimizeAnimBlueprintMemberVariableAccess" = "1";
          "bOptimizeForLocalShaderBuilds" = "1";
          "bSmoothFrameRate" = "0";
          "bSupportsGPUScene" = "1";
          "bSupportsWaveOperations" = "1";
          "bUseAsyncComputeContext" = "1";
          "bUseBackgroundCompiling" = "1";
          "bViewAccelerationEnabled" = "0";
          "RawMouseInputEnabled" = "1";
          "csv.trackWaitsGT" = "0";
          "csv.trackWaitsRT" = "0";
          "EnableMathOptimisations" = "1";
          "FX.AllowAsyncTick" = "1";
          "FX.BatchAsync" = "1";
          "FX.BatchAsyncBatchSize" = "8";
          "fx.DeferrPSCDeactivation" = "1";
          "fx.Niagara.AsyncCompute" = "1";
          "fx.NiagaraAllowRuntimeScalabilityChanges" = "1";
          "fx.NiagaraDataBufferMinSize" = "2048";
          "gc.AllowParallelGC" = "1";
          "gc.CreateGCClusters" = "1";
          "gc.MultithreadedDestructionEnabled" = "1";
          "GeometryCache.OffloadUpdate" = "1";
          "grass.MaxAsyncTasks" = "8";
          "grass.MaxCreatePerFrame" = "6";
          "grass.MaxInstancesPerComponent" = "49152";
          "grass.MinFramesToKeepGrass" = "60";
          "grass.UseHaltonDistribution" = "1";
          "landscape.RenderNanite" = "1";
          "MaxShaderJobBatchSize" = "150";
          "MaxShaderJobs" = "1000";
          "memory.logGenericPlatformMemoryStats" = "0";
          "niagara.CreateShadersOnLoad" = "1";
          "NumUnusedShaderCompilingThreads" = "2";
          "p.AsyncSceneEnabled" = "1";
          "p.Chaos.PerParticleCollision.ISPC" = "1";
          "p.Chaos.Spherical.ISPC" = "1";
          "p.Chaos.Spring.ISPC" = "1";
          "p.Chaos.TriangleMesh.ISPC" = "1";
          "p.Chaos.VelocityField.ISPC" = "1";
          "p.RemoveFarBodiesFromBVH" = "1";
          "pakcache.CachePerPakFile" = "1";
          "pakcache.MaxBlockMemory" = "384";
          "pakcache.MaxRequestSizeToLowerLevellKB" = "3072";
          "pakcache.MaxRequestsToLowerLevel" = "3";
          "pakcache.NumUnreferencedBlocksToCache" = "20";
          "pakcache.UseNewTrim" = "1";
          "r.AllowAsyncRenderThreadUpdatesDuringGamethreadUpdates" = "0";
          "r.AllowMultiThreadedShaderCreation" = "1";
          "r.AOAsyncBuildQueue" = "1";
          "r.AsyncCompute" = "1";
          "r.AsyncCompute.AdaptiveBuffer" = "1";
          "r.AsyncCompute.ParallelDispatch" = "1";
          "r.AsyncCreateLightPrimitiveInteractions" = "1";
          "r.AsyncPipelineCompile" = "1";
          "r.Bloom.AsyncCompute" = "1";
          "r.D3D.RemoveUnusedInterpolators" = "1";
          "r.DFShadowAsyncCompute" = "1";
          "r.DontLimitOnBattery" = "1";
          "r.EnableAsyncComputeVolumetricFog" = "1";
          "r.EnableMultiThreadedRendering" = "1";
          "r.ForceAllCoresForShaderCompiling" = "1";
          "r.ForceOcclusionQueryBatching" = "1";
          "r.GameThread.PriorityRedirectThreshold" = "3";
          "r.GTSyncType" = "2";
          "r.GraphicsThread.EnableBackgroundThreads" = "1";
          "r.GraphicsThread.UseThreadedDestruction" = "1";
          "r.OneFrameThreadLag" = "1";
          "r.ParallelBasePass" = "1";
          "r.ParallelCulling" = "1";
          "r.ParallelDestruction" = "1";
          "r.ParallelDistanceField" = "1";
          "r.ParallelDistributedScene" = "1";
          "r.ParallelGraphics" = "1";
          "r.ParallelInitViews" = "1";
          "r.ParallelMeshDrawCommands" = "1";
          "r.ParallelMeshMerge" = "1";
          "r.ParallelMeshProcessing" = "1";
          "r.ParallelNavBoundsCalc" = "1";
          "r.ParallelNavBoundsInit" = "1";
          "r.ParallelNavBoundsUpdate" = "1";
          "r.ParallelNavOctreeUpdate" = "1";
          "r.ParallelParticleUpdate" = "1";
          "r.ParallelPhysicsScene" = "1";
          "r.ParallelPhysicsStepAsync" = "1";
          "r.ParallelPostProcessing" = "1";
          "r.ParallelPrePass" = "1";
          "r.ParallelReflectionCaptures" = "1";
          "r.ParallelReflectionEnvironment" = "1";
          "r.ParallelRendering" = "1";
          "r.ParallelRenderUploads" = "1";
          "r.ParallelSceneCapture" = "1";
          "r.ParallelSceneColorGather" = "1";
          "r.ParallelShaderCompile" = "1";
          "r.ParallelTaskShaderCompilation" = "1";
          "r.ParallelTonemapping" = "1";
          "r.ParallelTranslucency" = "1";
          "r.ParallelVelocity" = "1";
          "r.ParallelZPrepass" = "1";
          "r.RDG.AsyncClothTick" = "1";
          "r.RDG.AsyncCompute" = "1";
          "r.RDG.AsyncPipelineCompile" = "1";
          "r.RDG.ParallelExecute" = "1";
          "r.RDG.ParallelUpdateRenderGraph" = "1";
          "r.RenderThread.EnableTaskGraphThread" = "1";
          "r.RenderThread.Priority" = "2";
          "r.RHICmdBuffer.EnableThreadedCompletion" = "1";
          "r.RHICmdBypass" = "0";
          "r.RHICmdUseParallelAlgorithms" = "1";
          "r.RHICmdUseThread" = "1";
          "r.RHIThread" = "1";
          "r.RHIThread.Priority" = "2";
          "r.RHI.UseParallelDispatch" = "1";
          "r.SceneRenderingThreadAffinity" = "-1";
          "r.ShaderCompiler.AllowDistributedCompilation" = "0";
          "r.ThreadedShaderCompilation" = "1";
          "r.ThreadPool.BackgroundThreadPriority" = "0";
          "r.ThreadPool.EnableBackgroundThreads" = "1";
          "r.ThreadPool.EnableHighPriorityThreads" = "1";
          "r.Threading.AllowWorkerThreadStall" = "0";
          "r.Threading.ThreadPriority" = "3";
          "r.UniformBufferPooling" = "1";
          "r.UseMultiThreadedRendering" = "1";
          "r.Visibility.FrustumCull.UseSphereTestFirst" = "1";
          "r.Visibility.TaskSchedule" = "0";
          "TaskGraph.Enable" = "1";
          "TaskGraph.ForkedProcessMaxWorkerThreads" = "4";
          "TaskGraph.NumForegroundWorkers" = "-1";
          "TaskGraph.NumWorkerThreads" = "-1";
          "TaskGraph.PrintBroadcastWarnings" = "0";
          "t.MaxFPS" = "0";
          "UseAllCores" = "1";
          "vm.OptimizeVMByteCode" = "1";
          "WorkerThreadPriority" = "0";
        };
      };
    };

    "${iniDir}/GameUserSettings.ini" = {
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
