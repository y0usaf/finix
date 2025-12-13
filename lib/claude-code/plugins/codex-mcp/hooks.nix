# Hooks configuration for codex-mcp plugin
# Mitigations: https://github.com/anthropics/claude-code/issues/10875
#              https://github.com/gabriel-dehan/claude_hooks/pull/15
# JSON output to stdout with exit 0 for proper hook parsing
{
  config = {
    SessionStart = [
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
      # Read stdin to get hook event name
      # Uses "advanced JSON API approach" per https://github.com/gabriel-dehan/claude_hooks/pull/15:
      # - Structured JSON output to stdout (not stderr)
      # - Exit code 0 (not non-zero) for proper hook STDOUT capture/parsing
      read -r input
      event=$(echo "$input" | jq -r '.hook_event_name // "UserPromptSubmit"')
      echo "{\"decision\":\"approve\",\"reason\":\"\",\"hookSpecificOutput\":{\"hookEventName\":\"$event\",\"additionalContext\":\"<system-reminder>\nUse Codex MCP when seeking reviews or second opinions.\n</system-reminder>\"}}"
      exit 0
    '';
  };
}
