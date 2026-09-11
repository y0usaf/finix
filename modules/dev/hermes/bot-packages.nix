{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.dev.hermes.packages = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    description = "Hermes runtime, desktop and Bots Mod UI.";
    default = pkgs.callPackage "${flakeInputs.hermes-tools}/packages.nix" {
      hermesSource = flakeInputs.hermes-agent;
      botsSource = flakeInputs.hermes-bots-mod;
      apiKeyFile = config.user.dev.hermes.apiKeyFile;
    };
  };
}
