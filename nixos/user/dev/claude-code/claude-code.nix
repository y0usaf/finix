{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code development tools";

    model = lib.mkOption {
      type = lib.types.str;
      default = "opus";
      description = "Claude model to use";
    };

    subagentModel = lib.mkOption {
      type = lib.types.str;
      default = "opus";
      description = "Claude model to use for subagents";
    };
  };

  config = lib.mkIf config.user.dev.claude-code.enable {
    environment.systemPackages = [
      pkgs.claude-code
      (pkgs.writeShellScriptBin "bunclaude" ''
        exec ${pkgs.bun}/bin/bunx --bun @anthropic-ai/claude-code --allow-dangerously-skip-permissions "$@"
      '')
    ];
  };
}
