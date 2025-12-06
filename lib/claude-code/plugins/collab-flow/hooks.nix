# Hooks configuration for collab-flow plugin
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
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/askuser-reminder.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "askuser-reminder.sh" = ''
      #!/usr/bin/env bash
      jq -n '{
        decision: "approve",
        reason: "",
        hookSpecificOutput: {
          hookEventName: "UserPromptSubmit",
          additionalContext: "<system-reminder>\nMANDATORY: You MUST use AskUserQuestion EVERY response. No exceptions.\n\nExample:\n\n<invoke name=\"AskUserQuestion\">\n<parameter name=\"questions\">[{\"question\": \"What approach do you prefer?\", \"header\": \"Architecture\", \"options\": [{\"label\": \"Option A\", \"description\": \"Why choose A\"}, {\"label\": \"Option B\", \"description\": \"Why choose B\"}], \"multiSelect\": false}]</parameter>\n</invoke>\n\nRules:\n- Ask at least ONE clarification or confirmation\n- Even if requirements seem clear, verify assumptions\n- NEVER proceed without asking first\n- Collaboration over autonomy\n</system-reminder>"
        }
      }'
      exit 0
    '';
  };
}
