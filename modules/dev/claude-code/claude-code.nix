{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  claudeCode = user.dev.claude-code;
in {
  options.user.dev.claude-code.enable = lib.mkEnableOption "Claude Code";

  config = lib.mkIf claudeCode.enable {
    environment.systemPackages = [
      pkgs.claude-code
      (pkgs.writeShellScriptBin "bunclaude" ''
        exec ${pkgs.bun}/bin/bunx --bun @anthropic-ai/claude-code --allow-dangerously-skip-permissions "$@"
      '')
    ];
  };
}
