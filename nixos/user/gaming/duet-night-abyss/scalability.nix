{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.gaming.core.enable {
    usr.files."${lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam.path}/steamapps/compatdata/3286820662/pfx/drive_c/users/steamuser/AppData/Local/Duet/Saved/Config/Windows/Scalability.ini" = {
      clobber = true;
      generator = lib.generators.toINI {};
      value = {
        # Tier 0: Low Performance
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

        # Tier 1: Medium
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

        # Tier 2: High
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

        # Tier 3: Epic (UE5 Standard)
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

        # Tier Cine: Maximum (Aggressive boosted quality)
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
