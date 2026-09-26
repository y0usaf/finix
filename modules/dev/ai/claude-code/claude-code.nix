{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.claude-code.enable = lib.mkEnableOption "Claude Code";

  config = lib.mkIf config.user.dev.claude-code.enable {
    # Managed settings apply to every Claude Code entry point (IDE extension,
    # npx, ...), not just the wrapper below, and live outside CLAUDE_CONFIG_DIR
    # so Claude Code can keep rewriting its own user settings.json.
    environment.etc."claude-code/managed-settings.json".text = builtins.toJSON {
      model = "claude-opus-5-5";
      effortLevel = "max";
      permissions.defaultMode = "bypassPermissions";
      skipDangerousModePermissionPrompt = true;
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "claude" ''
        # --append-system-prompt adds the shared compaction/ethics and
        # no-test-authoring blocks to Claude Code's default system prompt
        # without replacing it. The flag is
        # documented in `claude --help` ("Append a system prompt to the default
        # system prompt") and is accepted alongside every subcommand, so
        # `claude mcp ...`, `claude -p ...`, etc. keep working unchanged. The
        # clauses themselves live in config.user.dev.prompts.ethics and
        # config.user.dev.prompts.noTests.
        exec ${lib.getExe pkgs.claude-code} \
          --append-system-prompt ${lib.escapeShellArg (config.user.dev.prompts.ethics + "\n\n" + config.user.dev.prompts.noTests + "\n\n" + config.user.dev.prompts.noComments)} \
          "$@"
      '')
    ];
  };
}
