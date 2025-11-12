{
  config,
  lib,
  ...
}: {
  options.user.gaming.clair-obscur.engine = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Clair Obscur Engine.ini configuration";
    };
  };
  config = lib.mkIf config.user.gaming.clair-obscur.engine.enable {
    usr.files."${lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam.path}/steamapps/compatdata/1903340/pfx/drive_c/users/steamuser/AppData/Local/Sandfall/Saved/Config/Windows/Engine.ini" = {
      clobber = true;
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
  };
}
