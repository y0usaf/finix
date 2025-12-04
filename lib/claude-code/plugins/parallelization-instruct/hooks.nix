# Hooks configuration for parallelization-instruct plugin
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
      # Uses "advanced JSON API approach" per https://github.com/gabriel-dehan/claude_hooks/pull/15:
      # - Structured JSON output to stdout (not stderr)
      # - Exit code 0 (not non-zero) for proper hook STDOUT capture/parsing
      read -r input
      event=$(echo "$input" | jq -r '.hook_event_name // "UserPromptSubmit"')
      echo "{\"decision\":\"approve\",\"reason\":\"\",\"hookSpecificOutput\":{\"hookEventName\":\"$event\",\"additionalContext\":\"<system-reminder>\nMANDATORY: Parallelize ALL independent tool calls. Single message, multiple calls.\n\n<bad-example>Read file → wait → read another file</bad-example>\n<good-example>Read multiple files in single message</good-example>\n\nParallelizable tools: Read, Glob, Grep, Task, Bash, WebFetch, WebSearch, Edit, Write\n\nRULE: If B does not need output from A → PARALLEL in same message\n</system-reminder>\"}}"
      exit 0
    '';
  };
}
