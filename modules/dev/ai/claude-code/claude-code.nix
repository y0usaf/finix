{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.claude-code.enable = lib.mkEnableOption "Claude Code";

  config = lib.mkIf config.user.dev.claude-code.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "claude" ''
        # --append-system-prompt adds the shared no-test-authoring policy to
        # Claude Code's default system prompt without replacing it. The flag is
        # documented in `claude --help` ("Append a system prompt to the default
        # system prompt") and is accepted alongside every subcommand, so
        # `claude mcp ...`, `claude -p ...`, etc. keep working unchanged. The
        # clause itself lives in config.user.dev.prompts.noTests.
        exec ${lib.getExe pkgs.claude-code} \
          --dangerously-skip-permissions \
          --append-system-prompt ${lib.escapeShellArg config.user.dev.prompts.noTests} \
          "$@"
      '')
    ];
  };
}
