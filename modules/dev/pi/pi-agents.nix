{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  piAgentsPkg = flakeInputs."pi-agents".packages."${system}".default;
in {
  config = lib.mkIf config.user.dev.pi.enable {
    environment.variables.PI_AGENTS_PACKAGE = "${piAgentsPkg}";
    user.dev.pi.packageSources = lib.mkOrder 900 ["${piAgentsPkg}"];
  };
}
