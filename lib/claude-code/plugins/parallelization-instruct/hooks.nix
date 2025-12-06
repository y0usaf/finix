# Hooks configuration for parallelization-instruct plugin
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
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/parallel-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "parallel-reminder.sh" = ''
      #!/usr/bin/env bash
      jq -n '{
        decision: "approve",
        reason: "",
        hookSpecificOutput: {
          hookEventName: "UserPromptSubmit",
          additionalContext: "<system-reminder>\nMANDATORY: Parallelize ALL independent tool calls. Single message, multiple calls.\n\nExample (parallel):\n\n<invoke name=\"Read\">\n<parameter name=\"file_path\">/path/to/file1</parameter>\n</invoke>\n\n<invoke name=\"Read\">\n<parameter name=\"file_path\">/path/to/file2</parameter>\n</invoke>\n\n<invoke name=\"Bash\">\n<parameter name=\"command\">git status</parameter>\n<parameter name=\"description\">Check repo status</parameter>\n</invoke>\n\nIf B does not need output from A → PARALLEL in same message.\n</system-reminder>"
        }
      }'
      exit 0
    '';
  };
}
