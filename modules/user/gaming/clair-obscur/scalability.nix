{
  config,
  lib,
  ...
}: {
  options.user.gaming.clair-obscur.scalability = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Clair Obscur Scalability.ini configuration";
    };
  };
  config = lib.mkIf config.user.gaming.clair-obscur.scalability.enable {
    usr.files.".local/share/Steam/steamapps/compatdata/1903340/pfx/drive_c/users/steamuser/AppData/Local/Sandfall/Saved/Config/Windows/Scalability.ini" = {
      clobber = true;
      generator = lib.generators.toINI {};
      value = {
        "FoliageQuality@0" = {
          "foliage.DensityScale" = "0.1";
        };

        "FoliageQuality@1" = {
          "foliage.DensityScale" = "0.3";
        };

        "FoliageQuality@2" = {
          "foliage.DensityScale" = "0.6";
        };

        "FoliageQuality@3" = {
          "foliage.DensityScale" = "0.9";
        };

        "FoliageQuality@Cine" = {
          "foliage.DensityScale" = "0.9";
        };
      };
    };
  };
}
