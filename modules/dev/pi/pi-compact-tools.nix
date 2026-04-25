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
    user.dev.pi = {
      packageSources = lib.mkOrder 1200 ["${flakeInputs."pi-compact-tools".packages."${system}".default}"];
      extensionSettings."pi-compact" = {
        tools = {
          mode = "compact";
          gap = false;
        };
        user = {
          mode = "borderless";
          gap = true;
        };
        thinking.mode = "compact";
      };
    };
  };
}
