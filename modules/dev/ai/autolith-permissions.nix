{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.dev.autolith;
in {
  options.user.dev.autolith = {
    fullAccess = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start Autolith with full user privileges instead of sandboxed command approval.";
    };

    package = lib.mkOption {
      apply = package:
        if cfg.fullAccess
        then
          pkgs.symlinkJoin {
            name = "autolith-full-access";
            paths = [package];
            nativeBuildInputs = [pkgs.makeWrapper];
            postBuild = ''
              wrapProgram "$out/bin/autolith" --add-flags "--permissions full"
            '';
            meta = package.meta // {mainProgram = "autolith";};
          }
        else package;
    };
  };
}
