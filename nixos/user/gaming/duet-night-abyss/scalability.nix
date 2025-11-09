{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.gaming.duet-night-abyss.enable {
    usr.files.".local/share/Steam/steamapps/compatdata/3286820662/pfx/drive_c/users/steamuser/AppData/Local/Duet/Saved/Config/Windows/Scalability.ini" = {
      clobber = true;
      generator = lib.generators.toINI {};
      value = {
        "AntiAliasingQuality@0" = {
          "r.AntiAliasingMethod" = "0";
        };
        "AntiAliasingQuality@1" = {
          "r.AntiAliasingMethod" = "1";
        };
        "AntiAliasingQuality@2" = {
          "r.AntiAliasingMethod" = "1";
        };
        "AntiAliasingQuality@3" = {
          "r.AntiAliasingMethod" = "1";
        };
        "AntiAliasingQuality@4" = {
          "r.AntiAliasingMethod" = "1";
        };
        "EffectsQuality@0" = {
          "r.SSS.Quality" = "0";
          "r.SSR" = "0";
          "r.SSR.MaxRoughness" = "0.4";
          "r.DetailMode" = "0";
          "r.EmitterSpawnRateScale" = "1.0";
          "r.ReflectionQuality" = "0";
          "r.LightShaftQuality" = "1";
          "r.RefractionQuality" = "0";
          "r.TranslucencyLightingVolumeDim" = "24";
          "r.TranslucencyVolumeBlur" = "0";
          "FX.Niagara.QualityLevel" = "0";
          "r.ParticleLightQuality" = "0";
          "r.ParticleLODBias" = "2";
        };
        "EffectsQuality@1" = {
          "r.SSS.Quality" = "1";
          "r.DetailMode" = "1";
          "r.EmitterSpawnRateScale" = "2.0";
          "r.SSR.Quality" = "1";
          "r.SSR.MaxRoughness" = "0.60";
          "r.ReflectionQuality" = "1";
          "r.LightShaftQuality" = "1";
          "r.RefractionQuality" = "1";
          "r.TranslucencyLightingVolumeDim" = "32";
          "r.TranslucencyVolumeBlur" = "0";
          "FX.Niagara.QualityLevel" = "1";
          "r.ParticleLightQuality" = "1";
          "r.ParticleLODBias" = "0";
        };
        "EffectsQuality@2" = {
          "r.SSS.Quality" = "2";
          "r.DetailMode" = "2";
          "r.EmitterSpawnRateScale" = "4.0";
          "r.SSR.Quality" = "2";
          "r.SSR.MaxRoughness" = "0.80";
          "r.ReflectionQuality" = "2";
          "r.LightShaftQuality" = "1";
          "r.RefractionQuality" = "2";
          "r.TranslucencyLightingVolumeDim" = "48";
          "r.TranslucencyVolumeBlur" = "1";
          "FX.Niagara.QualityLevel" = "2";
          "r.ParticleLightQuality" = "2";
          "r.ParticleLODBias" = "-1";
        };
        "EffectsQuality@3" = {
          "r.SSS.Quality" = "2";
          "r.DetailMode" = "2";
          "r.EmitterSpawnRateScale" = "6.0";
          "r.SSR.Quality" = "2";
          "r.SSR.MaxRoughness" = "1.0";
          "r.ReflectionQuality" = "3";
          "r.LightShaftQuality" = "2";
          "r.RefractionQuality" = "3";
          "r.TranslucencyLightingVolumeDim" = "64";
          "r.TranslucencyVolumeBlur" = "1";
          "FX.Niagara.QualityLevel" = "3";
          "r.ParticleLightQuality" = "3";
          "r.ParticleLODBias" = "-1";
        };
        "EffectsQuality@4" = {
          "r.SSS.Quality" = "3";
          "r.DetailMode" = "2";
          "r.EmitterSpawnRateScale" = "8.0";
          "r.SSR.Quality" = "3";
          "r.SSR.MaxRoughness" = "1.0";
          "r.ReflectionQuality" = "3";
          "r.LightShaftQuality" = "3";
          "r.RefractionQuality" = "3";
          "r.TranslucencyLightingVolumeDim" = "64";
          "r.TranslucencyVolumeBlur" = "1";
          "FX.Niagara.QualityLevel" = "3";
          "r.ParticleLightQuality" = "3";
          "r.ParticleLODBias" = "-1";
        };
        "FoliageQuality@0" = {
          "foliage.DensityScale" = "1.0";
          "Grass.DensityScale" = "1.0";
          "Bush.DensityScale" = "1.0";
          "Tree.DensityScale" = "1.0";
          "Leaf.DensityScale" = "1.0";
          "foliage.LODDistanceScale" = "1.0";
          "r.FoliageLODBias" = "1";
        };
        "FoliageQuality@1" = {
          "foliage.DensityScale" = "2.0";
          "Grass.DensityScale" = "2.0";
          "Bush.DensityScale" = "2.0";
          "Tree.DensityScale" = "2.0";
          "Leaf.DensityScale" = "2.0";
          "foliage.LODDistanceScale" = "2.0";
          "r.FoliageLODBias" = "0";
        };
        "FoliageQuality@2" = {
          "foliage.DensityScale" = "4.0";
          "Grass.DensityScale" = "4.0";
          "Bush.DensityScale" = "4.0";
          "Tree.DensityScale" = "4.0";
          "Leaf.DensityScale" = "4.0";
          "foliage.LODDistanceScale" = "4.0";
          "r.FoliageLODBias" = "-1";
        };
        "FoliageQuality@3" = {
          "foliage.DensityScale" = "6.0";
          "Grass.DensityScale" = "6.0";
          "Bush.DensityScale" = "6.0";
          "Tree.DensityScale" = "6.0";
          "Leaf.DensityScale" = "6.0";
          "foliage.LODDistanceScale" = "6.0";
          "r.FoliageLODBias" = "-1";
        };
        "FoliageQuality@4" = {
          "foliage.DensityScale" = "8.0";
          "Grass.DensityScale" = "8.0";
          "Bush.DensityScale" = "8.0";
          "Tree.DensityScale" = "8.0";
          "Leaf.DensityScale" = "8.0";
          "foliage.LODDistanceScale" = "8.0";
          "r.FoliageLODBias" = "-1";
        };
        "PostProcessQuality@0" = {
          "r.BloomQuality" = "1";
          "r.AmbientOcclusionLevels" = "0";
          "r.AmbientOcclusionRadiusScale" = "1.0";
          "r.HZBOcclusion" = "1";
        };
        "PostProcessQuality@1" = {
          "r.BloomQuality" = "2";
          "r.AmbientOcclusionLevels" = "1";
          "r.AmbientOcclusionRadiusScale" = "2.0";
          "r.HZBOcclusion" = "1";
        };
        "PostProcessQuality@2" = {
          "r.BloomQuality" = "3";
          "r.AmbientOcclusionLevels" = "2";
          "r.AmbientOcclusionRadiusScale" = "4.0";
          "r.HZBOcclusion" = "1";
        };
        "PostProcessQuality@3" = {
          "r.BloomQuality" = "4";
          "r.AmbientOcclusionLevels" = "3";
          "r.AmbientOcclusionRadiusScale" = "6.0";
          "r.HZBOcclusion" = "1";
        };
        "PostProcessQuality@4" = {
          "r.BloomQuality" = "4";
          "r.AmbientOcclusionLevels" = "4";
          "r.AmbientOcclusionRadiusScale" = "10.0";
          "r.HZBOcclusion" = "1";
        };
        "ShadowQuality@0" = {
          "r.ShadowQuality" = "2";
          "r.Shadow.PerObject" = "2";
          "r.Shadow.ContactShadow" = "0";
          "r.Shadow.FadeResolution" = "70";
          "r.Shadow.TexelsPerPixel" = "1.0";
          "r.Shadow.MaxCascades" = "2";
          "r.Shadow.CSM.TransitionScale" = "1.0";
          "r.Shadow.TransitionScale" = "1.0";
          "r.Shadow.DepthBias" = "16";
          "r.Shadow.MaxCSMResolution" = "256";
          "r.Shadow.MinCSMResolution" = "256";
          "r.Shadow.MaxResolution" = "256";
          "r.Shadow.MinResolution" = "256";
          "r.Shadow.PerObjectShadowMapResolution" = "256";
          "r.Shadow.PerObjectResolutionMax" = "256";
          "r.Shadow.PerObjectResolutionMin" = "256";
          "r.Shadow.RadiusThreshold" = "0.050";
          "r.Shadow.DistanceScale" = "1.0";
          "r.Shadow.FarShadowDistanceOverride" = "15000.0";
          "r.Shadow.PreShadowResolutionFactor" = "1.0";
          "r.DFDistanceScale" = "1.0";
        };
        "ShadowQuality@1" = {
          "r.ShadowQuality" = "2";
          "r.Shadow.PerObject" = "2";
          "r.Shadow.ContactShadow" = "0";
          "r.Shadow.FadeResolution" = "64";
          "r.Shadow.TexelsPerPixel" = "1.0";
          "r.Shadow.MaxCascades" = "4";
          "r.Shadow.CSM.TransitionScale" = "4.0";
          "r.Shadow.TransitionScale" = "4.0";
          "r.Shadow.DepthBias" = "8";
          "r.Shadow.MaxCSMResolution" = "512";
          "r.Shadow.MinCSMResolution" = "512";
          "r.Shadow.MaxResolution" = "512";
          "r.Shadow.MinResolution" = "512";
          "r.Shadow.PerObjectShadowMapResolution" = "512";
          "r.Shadow.PerObjectResolutionMax" = "512";
          "r.Shadow.PerObjectResolutionMin" = "512";
          "r.Shadow.RadiusThreshold" = "0.050";
          "r.Shadow.DistanceScale" = "4.0";
          "r.Shadow.FarShadowDistanceOverride" = "25000.0";
          "r.Shadow.PreShadowResolutionFactor" = "1.0";
          "r.DFDistanceScale" = "4.0";
        };
        "ShadowQuality@2" = {
          "r.ShadowQuality" = "3";
          "r.Shadow.PerObject" = "3";
          "r.Shadow.ContactShadow" = "0";
          "r.Shadow.FadeResolution" = "50";
          "r.Shadow.TexelsPerPixel" = "2.0";
          "r.Shadow.MaxCascades" = "6";
          "r.Shadow.CSM.TransitionScale" = "5.0";
          "r.Shadow.TransitionScale" = "5.0";
          "r.Shadow.DepthBias" = "4";
          "r.Shadow.MaxCSMResolution" = "1024";
          "r.Shadow.MinCSMResolution" = "1024";
          "r.Shadow.MaxResolution" = "1024";
          "r.Shadow.MinResolution" = "1024";
          "r.Shadow.PerObjectShadowMapResolution" = "1024";
          "r.Shadow.PerObjectResolutionMax" = "1024";
          "r.Shadow.PerObjectResolutionMin" = "1024";
          "r.Shadow.RadiusThreshold" = "0.020";
          "r.Shadow.DistanceScale" = "10.0";
          "r.Shadow.FarShadowDistanceOverride" = "45000.0";
          "r.Shadow.PreShadowResolutionFactor" = "1.0";
          "r.DFDistanceScale" = "10.0";
        };
        "ShadowQuality@3" = {
          "r.ShadowQuality" = "4";
          "r.Shadow.PerObject" = "4";
          "r.Shadow.ContactShadow" = "1";
          "r.Shadow.FadeResolution" = "0.050";
          "r.Shadow.TexelsPerPixel" = "2.0";
          "r.Shadow.MaxCascades" = "8";
          "r.Shadow.CSM.TransitionScale" = "10.0";
          "r.Shadow.TransitionScale" = "10.0";
          "r.Shadow.DepthBias" = "2";
          "r.Shadow.MaxCSMResolution" = "2048";
          "r.Shadow.MinCSMResolution" = "2048";
          "r.Shadow.MinResolution" = "2048";
          "r.Shadow.MaxResolution" = "2048";
          "r.Shadow.PerObjectShadowMapResolution" = "2048";
          "r.Shadow.PerObjectResolutionMax" = "2048";
          "r.Shadow.PerObjectResolutionMin" = "2048";
          "r.Shadow.RadiusThreshold" = "0.020";
          "r.Shadow.DistanceScale" = "20.0";
          "r.Shadow.FarShadowDistanceOverride" = "65000.0";
          "r.Shadow.PreShadowResolutionFactor" = "1.0";
          "r.DFDistanceScale" = "20.0";
        };
        "ShadowQuality@4" = {
          "r.ShadowQuality" = "5";
          "r.Shadow.PerObject" = "6";
          "r.Shadow.ContactShadow" = "1";
          "r.Shadow.FadeResolution" = "0";
          "r.Shadow.TexelsPerPixel" = "4.0";
          "r.Shadow.MaxCascades" = "10";
          "r.Shadow.CSM.TransitionScale" = "10.0";
          "r.Shadow.TransitionScale" = "10.0";
          "r.Shadow.DepthBias" = "0";
          "r.Shadow.MaxCSMResolution" = "2048";
          "r.Shadow.MinCSMResolution" = "2048";
          "r.Shadow.MinResolution" = "2048";
          "r.Shadow.MaxResolution" = "2048";
          "r.Shadow.PerObjectShadowMapResolution" = "2048";
          "r.Shadow.PerObjectResolutionMax" = "2048";
          "r.Shadow.PerObjectResolutionMin" = "2048";
          "r.Shadow.RadiusThreshold" = "0.001";
          "r.Shadow.DistanceScale" = "50.0";
          "r.Shadow.FarShadowDistanceOverride" = "100000.0";
          "r.Shadow.PreShadowResolutionFactor" = "2.0";
          "r.DFDistanceScale" = "50.0";
        };
        "ShadingQuality@0" = {
          "r.MaterialQualityLevel" = "0";
        };
        "ShadingQuality@1" = {
          "r.MaterialQualityLevel" = "1";
        };
        "ShadingQuality@2" = {
          "r.MaterialQualityLevel" = "2";
        };
        "ShadingQuality@3" = {
          "r.MaterialQualityLevel" = "3";
        };
        "ShadingQuality@4" = {
          "r.MaterialQualityLevel" = "4";
        };
        "TextureQuality@0" = {
          "r.MaxAnisotropy" = "0";
          "r.VT.MaxAnisotropy" = "0";
          "r.Streaming.Boost" = "0.3";
        };
        "TextureQuality@1" = {
          "r.MaxAnisotropy" = "4";
          "r.VT.MaxAnisotropy" = "4";
          "r.Streaming.Boost" = "1.0";
        };
        "TextureQuality@2" = {
          "r.MaxAnisotropy" = "4";
          "r.VT.MaxAnisotropy" = "4";
          "r.Streaming.Boost" = "1.5";
        };
        "TextureQuality@3" = {
          "r.MaxAnisotropy" = "8";
          "r.VT.MaxAnisotropy" = "8";
          "r.Streaming.Boost" = "2.0";
        };
        "TextureQuality@4" = {
          "r.MaxAnisotropy" = "16";
          "r.VT.MaxAnisotropy" = "16";
          "r.Streaming.Boost" = "3.0";
        };
        "ViewDistanceQuality@0" = {
          "r.foliageDistanceScale" = "1.0";
          "r.ViewDistanceScale" = "1.0";
          "r.LightMaxDrawDistanceScale" = "1.0";
          "r.StaticMeshLODDistanceScale" = "1.0";
          "r.MipMapLODBias" = "1";
          "r.AOMaxViewDistance" = "5000";
          "r.SkeletalMeshLODBias" = "1";
          "r.StaticMeshLODBias" = "1";
          "r.LandscapeLODBias" = "1";
        };
        "ViewDistanceQuality@1" = {
          "r.foliageDistanceScale" = "2.0";
          "r.ViewDistanceScale" = "2.0";
          "r.LightMaxDrawDistanceScale" = "5.0";
          "r.StaticMeshLODDistanceScale" = "0.500";
          "r.AOMaxViewDistance" = "10000";
          "r.MipMapLODBias" = "-1";
          "r.SkeletalMeshLODBias" = "-1";
          "r.StaticMeshLODBias" = "0";
          "r.LandscapeLODBias" = "0";
        };
        "ViewDistanceQuality@2" = {
          "r.foliageDistanceScale" = "30.0";
          "r.ViewDistanceScale" = "30.0";
          "r.LightMaxDrawDistanceScale" = "50.0";
          "r.StaticMeshLODDistanceScale" = "0.100";
          "r.AOMaxViewDistance" = "10000";
          "r.MipMapLODBias" = "-1";
          "r.SkeletalMeshLODBias" = "-1";
          "r.StaticMeshLODBias" = "-1";
          "r.LandscapeLODBias" = "-1";
        };
        "ViewDistanceQuality@3" = {
          "r.foliageDistanceScale" = "50.0";
          "r.ViewDistanceScale" = "50.0";
          "r.LightMaxDrawDistanceScale" = "80.0";
          "r.StaticMeshLODDistanceScale" = "0.0050";
          "r.AOMaxViewDistance" = "30000";
          "r.MipMapLODBias" = "-1";
          "r.SkeletalMeshLODBias" = "-1";
          "r.StaticMeshLODBias" = "-1";
          "r.LandscapeLODBias" = "-1";
        };
        "ViewDistanceQuality@4" = {
          "r.foliageDistanceScale" = "100.0";
          "r.ViewDistanceScale" = "100.0";
          "r.LightMaxDrawDistanceScale" = "100.0";
          "r.StaticMeshLODDistanceScale" = "0.0001";
          "r.AOMaxViewDistance" = "50000";
          "r.MipMapLODBias" = "-1";
          "r.SkeletalMeshLODBias" = "-1";
          "r.StaticMeshLODBias" = "-1";
          "r.LandscapeLODBias" = "-1";
        };
      };
    };
  };
}
