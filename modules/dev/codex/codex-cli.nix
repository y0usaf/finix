{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.dev.codex-cli = {
    enable = lib.mkEnableOption "Codex CLI (OpenAI's command-line interface)";
  };

  config = lib.mkIf config.user.dev.codex-cli.enable {
    environment.systemPackages = [
      flakeInputs.codex-cli-nix.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };
}
