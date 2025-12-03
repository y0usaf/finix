# Hooks configuration for parallelization-instruct plugin
{
  config = {
    SessionStart = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/parallel-reminder.sh";
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
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/parallel-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "parallel-reminder.sh" = ''
      #!/usr/bin/env bash
      # Read stdin to get hook event name
      read -r input
      event=$(echo "$input" | jq -r '.hook_event_name // "UserPromptSubmit"')
      echo "{\"decision\":\"approve\",\"reason\":\"\",\"hookSpecificOutput\":{\"hookEventName\":\"$event\",\"additionalContext\":\"<system-reminder>\nMANDATORY: Parallelize ALL independent tool calls. Single message, multiple calls.\n\n<bad-example>Read file → wait → read another file</bad-example>\n<good-example>Read multiple files in single message</good-example>\n\nParallelizable tools: Read, Glob, Grep, Task, Bash, WebFetch, WebSearch, Edit, Write\n\nRULE: If B does not need output from A → PARALLEL in same message\n</system-reminder>\"}}"
      exit 0
    '';
  };
}
