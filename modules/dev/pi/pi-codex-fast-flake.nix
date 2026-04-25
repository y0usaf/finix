{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.user.dev.pi;
  piCodexFastPkg = flakeInputs."pi-codex-fast-flake".packages."${system}".default;
in {
  config = lib.mkIf cfg.enable {
    user = {
      dev = {
        pi = {
          packageSources = lib.mkOrder 1000 ["${piCodexFastPkg}"];
          extensionSettings = {
            "codex-fast" = true;
          };
        };
      };
    };
  };
}
