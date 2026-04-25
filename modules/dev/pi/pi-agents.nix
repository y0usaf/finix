{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.user.dev.pi;
  piAgentsPkg = flakeInputs."pi-agents".packages."${system}".default;
in {
  config = lib.mkIf cfg.enable {
    environment.variables.PI_AGENTS_PACKAGE = "${piAgentsPkg}";
    user.dev.pi.packageSources = lib.mkOrder 900 ["${piAgentsPkg}"];
  };
}
