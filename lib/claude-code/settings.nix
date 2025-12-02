{
  includeCoAuthoredBy = false;
  model = "claude-opus-4-5";
  env = {
    MAX_THINKING_TOKENS = "31999";
    BASH_DEFAULT_TIMEOUT_MS = "900000";
    DISABLE_TELEMETRY = "1";
    CLAUDE_CODE_SUBAGENT_MODEL = "claude-haiku-4-5";
  };
  statusLine = {
    type = "command";
    command = "bunx ccusage statusline";
  };
  hooks = {
    # UserPromptSubmit: always-on tool reminders
    UserPromptSubmit = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/todowrite-reminder.sh";
          }
          {
            type = "command";
            command = "~/.claude/hooks/askuser-reminder.sh";
          }
          {
            type = "command";
            command = "~/.claude/hooks/parallel-reminder.sh";
          }
          {
            type = "command";
            command = "~/.claude/hooks/codex-reminder.sh";
          }
        ];
      }
    ];
    # Stop: sound/transcript hooks
    Stop = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "bun ~/.claude/hooks/stop.ts --chat";
          }
        ];
      }
    ];
    Notification = [
      {
        matcher = "permission_prompt";
        hooks = [
          {
            type = "command";
            command = "bun ~/.claude/hooks/notification.ts --notify";
          }
        ];
      }
    ];
  };
}
