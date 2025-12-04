# Hooks configuration for collab-flow plugin
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
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/askuser-reminder.sh";
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
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/askuser-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "askuser-reminder.sh" = ''
      #!/usr/bin/env bash
      # Read stdin to get hook event name
      # Uses "advanced JSON API approach" per https://github.com/gabriel-dehan/claude_hooks/pull/15:
      # - Structured JSON output to stdout (not stderr)
      # - Exit code 0 (not non-zero) for proper hook STDOUT capture/parsing
      read -r input
      event=$(echo "$input" | jq -r '.hook_event_name // "UserPromptSubmit"')
      echo "{\"decision\":\"approve\",\"reason\":\"\",\"hookSpecificOutput\":{\"hookEventName\":\"$event\",\"additionalContext\":\"<system-reminder>\nMANDATORY: You MUST use AskUserQuestion EVERY response. No exceptions.\n- Ask at least ONE clarification or confirmation\n- Even if requirements seem clear, verify assumptions\n- NEVER proceed without asking first\n- Collaboration over autonomy\n</system-reminder>\"}}"
      exit 0
    '';
  };
}
