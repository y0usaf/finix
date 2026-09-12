{
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.dev.ai.hermes.projectRunner = lib.mkOption {
    type = lib.types.package;
    default = pkgs.callPackage "${flakeInputs.hermes-tools}/package.nix" {};
    description = "Optional project scheduler; uses the active Hermes CLI and profiles.";
  };
}
