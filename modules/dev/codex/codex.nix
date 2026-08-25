{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.dev.codex.enable = lib.mkEnableOption "Codex CLI";

  config = lib.mkIf config.user.dev.codex.enable {
    environment.systemPackages = [
      flakeInputs.codex-cli-nix.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };
}
