# Hooks configuration for todowrite-instruct plugin
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
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/todowrite-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "todowrite-reminder.sh" = ''
      #!/usr/bin/env bash
      # Uses "advanced JSON API approach" per https://github.com/gabriel-dehan/claude_hooks/pull/15:
      # - Structured JSON output to stdout (not stderr)
      # - Exit code 0 (not non-zero) for proper hook STDOUT capture/parsing
      echo "{\"decision\":\"approve\",\"reason\":\"\",\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":\"<system-reminder>\nMANDATORY: You MUST use TodoWrite for EVERY task. No exceptions.\n- Create task BEFORE any work\n- Exactly ONE task in_progress at a time\n- Mark completed IMMEDIATELY when done\n- This applies to ALL tasks, not just complex ones\n</system-reminder>\"}}"
      exit 0
    '';
  };
}
