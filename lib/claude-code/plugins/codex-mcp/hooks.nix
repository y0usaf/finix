# Hooks configuration for codex-mcp plugin
# Mitigations: https://github.com/anthropics/claude-code/issues/10875
#              https://github.com/gabriel-dehan/claude_hooks/pull/15
# JSON output to stdout with exit 0 for proper hook parsing
{
  config = {
    UserPromptSubmit = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/codex-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "codex-reminder.sh" = ''
      #!/usr/bin/env bash
      # Uses "advanced JSON API approach" per https://github.com/gabriel-dehan/claude_hooks/pull/15:
      # - Structured JSON output to stdout (not stderr)
      # - Exit code 0 (not non-zero) for proper hook STDOUT capture/parsing
      echo "{\"decision\":\"approve\",\"reason\":\"\",\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":\"<system-reminder>\nMANDATORY: Use Codex MCP on every response for discussion and review.\n</system-reminder>\"}}"
      exit 0
    '';
  };
}
