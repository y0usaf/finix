{
  config,
  lib,
  ...
}: let
  cfg = config.finix.persistence;
in {
  options.finix.persistence = {
    homeCondition = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Finit condition that holds once the persisted home is mounted; null on hosts whose home is not rebuilt at boot.";
    };

    homeServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Finit services that read or write the user's home and must start after the persisted home is mounted.";
    };
  };

  config.finit.services = lib.mkIf (cfg.homeCondition != null) (
    lib.genAttrs cfg.homeServices (_: {conditions = [cfg.homeCondition];})
  );
}
