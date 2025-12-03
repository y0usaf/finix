# Hooks configuration for todowrite-instruct plugin
{
  config = {
    SessionStart = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/todowrite-reminder.sh";
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
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/todowrite-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "todowrite-reminder.sh" = ''
      #!/usr/bin/env bash
      # Read stdin to get hook event name
      read -r input
      event=$(echo "$input" | jq -r '.hook_event_name // "UserPromptSubmit"')
      echo "{\"decision\":\"approve\",\"reason\":\"\",\"hookSpecificOutput\":{\"hookEventName\":\"$event\",\"additionalContext\":\"<system-reminder>\nMANDATORY: You MUST use TodoWrite for EVERY task. No exceptions.\n- Create task BEFORE any work\n- Exactly ONE task in_progress at a time\n- Mark completed IMMEDIATELY when done\n- This applies to ALL tasks, not just complex ones\n</system-reminder>\"}}"
      exit 0
    '';
  };
}
