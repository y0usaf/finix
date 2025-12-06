# Hooks configuration for codex-mcp plugin
# Uses Codex CLI directly for code review on every response
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
            command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/codex-review.sh";
          }
        ];
      }
    ];
  };

  scripts = {
    "codex-review.sh" = ''
      #!/usr/bin/env bash
      CODEX_OUTPUT=$(bunx @openai/codex review --uncommitted 2>&1 | head -100)
      jq -n \
        --arg codex_output "$CODEX_OUTPUT" \
        '{
          decision: "approve",
          reason: "",
          hookSpecificOutput: {
            hookEventName: "UserPromptSubmit",
            additionalContext: ("<system-reminder>\nCODEX REVIEW:\n" + $codex_output + "\n</system-reminder>")
          }
        }'
      exit 0
    '';
  };
}
