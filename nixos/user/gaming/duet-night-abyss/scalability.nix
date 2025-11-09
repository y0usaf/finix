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
        "EffectsQuality" = {
          "r.SSS.Quality" = "3";
          "r.SSR.Quality" = "3";
          "r.SSR.MaxRoughness" = "1.0";
          "r.ReflectionQuality" = "3";
          "r.LightShaftQuality" = "3";
          "r.RefractionQuality" = "3";
          "FX.Niagara.QualityLevel" = "3";
          "r.ParticleLightQuality" = "3";
        };
        "FoliageQuality" = {
          "foliage.DensityScale" = "8.0";
          "Grass.DensityScale" = "8.0";
          "Tree.DensityScale" = "8.0";
          "foliage.LODDistanceScale" = "8.0";
        };
        "ShadowQuality" = {
          "r.ShadowQuality" = "5";
          "r.Shadow.PerObject" = "6";
          "r.Shadow.ContactShadow" = "1";
          "r.Shadow.MaxCascades" = "10";
          "r.Shadow.MaxResolution" = "2048";
          "r.Shadow.PerObjectShadowMapResolution" = "2048";
          "r.Shadow.DepthBias" = "0";
        };
        "TextureQuality" = {
          "r.MaxAnisotropy" = "16";
          "r.VT.MaxAnisotropy" = "16";
          "r.Streaming.Boost" = "3.0";
        };
        "ViewDistanceQuality" = {
          "r.ViewDistanceScale" = "100.0";
          "r.foliageDistanceScale" = "100.0";
          "r.LightMaxDrawDistanceScale" = "100.0";
          "r.StaticMeshLODDistanceScale" = "0.0001";
          "r.AOMaxViewDistance" = "50000";
        };
      };
    };
  };
}
