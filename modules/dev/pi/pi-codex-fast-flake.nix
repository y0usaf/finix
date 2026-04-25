{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  config = lib.mkIf config.user.dev.pi.enable {
    user = {
      dev = {
        pi = {
          packageSources = lib.mkOrder 1000 ["${flakeInputs."pi-codex-fast-flake".packages."${system}".default}"];
          extensionSettings = {
            "codex-fast" = true;
          };
        };
      };
    };
  };
}
