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
      (pkgs.writeShellScriptBin "codex" ''
        exec ${lib.getExe flakeInputs.codex-cli-nix.packages."${pkgs.stdenv.hostPlatform.system}".default} --dangerously-bypass-approvals-and-sandbox "$@"
      '')
    ];
  };
}
