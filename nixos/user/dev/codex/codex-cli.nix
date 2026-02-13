{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  codex-cli = flakeInputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.user.dev.codex-cli = {
    enable = lib.mkEnableOption "Codex CLI (OpenAI's command-line interface)";
  };

  config = lib.mkIf config.user.dev.codex-cli.enable {
    environment.systemPackages = [
      codex-cli
    ];
  };
}
