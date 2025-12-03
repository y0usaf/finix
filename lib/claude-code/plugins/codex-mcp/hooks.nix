# Hooks configuration for codex-mcp plugin
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
      read -r input
      event=$(echo "$input" | jq -r '.hook_event_name // "UserPromptSubmit"')
      echo "{\"decision\":\"approve\",\"reason\":\"\",\"hookSpecificOutput\":{\"hookEventName\":\"$event\",\"additionalContext\":\"<system-reminder>\nGUIDANCE: Use mcp__plugin_codex-mcp_codex__codex for second opinions and out-of-distribution thinking.\n- Code reviews → get Codex review\n- Design decisions → bounce off Codex\n- Stuck or uncertain → ask Codex\n- Different perspective → Codex has different training\n</system-reminder>\"}}"
      exit 0
    '';
  };
}
