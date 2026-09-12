{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.dev.work.vercel;
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.intersectLists (map lib.toLower cfg.personalOwners) (map lib.toLower cfg.workOwners) == [];
        message = "Vercel personalOwners and workOwners must not overlap.";
      }
    ];
    environment.systemPackages = [cfg.wrappedPackage];
  };
}
